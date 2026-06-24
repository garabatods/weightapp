(() => {
  const storageKey = "leafstepNutritionistPrototype";
  const demoAccessCode = "leafstep-pro";
  const appStateVersion = 4;
  const richDemoDataVersion = "2026-06-23-rich-dishes";
  const pageSizeDefault = 25;
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const mealGroups = ["Breakfast", "Lunch", "Dinner", "Snack"];
  const presetTags = [
    "high protein",
    "low carb",
    "diabetes-friendly",
    "vegetarian",
    "plant forward",
    "fiber focused",
    "quick",
    "meal prep",
    "family friendly",
    "breakfast",
    "lunch",
    "dinner",
    "snack",
    "mediterranean",
    "mexican-inspired",
  ];
  const dishFilterGroups = {
    meal: {
      label: "Meal type",
      allLabel: "All meals",
      tags: ["breakfast", "lunch", "dinner", "snack"],
    },
    nutrition: {
      label: "Nutrition",
      allLabel: "All nutrition",
      tags: ["high protein", "low carb", "diabetes-friendly", "vegetarian", "plant forward", "fiber focused"],
    },
    prep: {
      label: "Prep",
      allLabel: "All prep",
      tags: ["quick", "meal prep", "family friendly"],
    },
    cuisine: {
      label: "Cuisine",
      allLabel: "All cuisines",
      tags: ["mediterranean", "mexican-inspired"],
    },
  };
  const dishPhotos = [
    { value: "assets/pro/dishes/chicken-salad-bowl.png", label: "Chicken salad bowl" },
    { value: "assets/pro/dishes/greek-yogurt-berry-bowl.png", label: "Greek yogurt bowl" },
    { value: "assets/pro/dishes/salmon-vegetable-plate.png", label: "Salmon plate" },
    { value: "assets/pro/dishes/tofu-grain-bowl.png", label: "Tofu grain bowl" },
  ];

  const state = normalizeState(loadState());

  const loginPanel = document.querySelector("#login-panel");
  const appPanel = document.querySelector("#app-panel");
  const loginForm = document.querySelector("#login-form");
  const loginError = document.querySelector("#login-error");
  const accessCode = document.querySelector("#access-code");
  const searchInput = document.querySelector("#workspace-search");
  const searchWrapper = document.querySelector("#search-wrapper");
  const searchLabel = document.querySelector("#search-label");
  const viewTitle = document.querySelector("#view-title");
  const viewKicker = document.querySelector("#view-kicker");
  const breadcrumbs = document.querySelector("#breadcrumbs");
  const saveStatus = document.querySelector("#save-status");
  const sidebarToggle = document.querySelector("#sidebar-toggle");
  const sidebarToggleLabel = document.querySelector(".toggle-label");
  const patientDialog = document.querySelector("#patient-dialog");
  const planDialog = document.querySelector("#plan-dialog");
  const planForm = document.querySelector("#plan-form");
  const slotDialog = document.querySelector("#slot-dialog");
  const slotForm = document.querySelector("#slot-form");
  const pairingDialog = document.querySelector("#pairing-dialog");
  const confirmDialog = document.querySelector("#confirm-dialog");
  const confirmTitle = document.querySelector("#confirm-dialog-title");
  const confirmBody = document.querySelector("#confirm-dialog-body");
  const confirmApprove = document.querySelector("#confirm-approve");
  const confirmCancel = document.querySelector("#confirm-cancel");

  let selectedPatientId = state.selectedPatientId || state.patients[0]?.id || null;
  let selectedPlanId = state.selectedPlanId || state.plans[0]?.id || null;
  let selectedDishId = state.selectedDishId || state.dishes[0]?.id || null;
  let sidebarCollapsed = Boolean(state.sidebarCollapsed);
  let route = parseRoute(window.location.hash);
  let indexes = buildIndexes();
  let searchTimer = null;

  const viewMeta = {
    overview: { title: "Overview", kicker: "Practice workspace", search: false, actions: ["patient", "plan", "dish"] },
    patients: { title: "Patients", kicker: "Patient planning", search: true, searchKey: "patients", searchLabel: "Search patients", placeholder: "Search patients or assigned plans", actions: ["patient"] },
    "meal-plans": { title: "Meal plans", kicker: "Plan templates", search: true, searchKey: "plans", searchLabel: "Search meal plans", placeholder: "Search meal plans", actions: ["plan", "dish"] },
    "dish-library": { title: "Dish library", kicker: "Reusable dishes", search: true, searchKey: "dishes", searchLabel: "Search dishes", placeholder: "Search dishes", actions: ["dish"] },
    privacy: { title: "Privacy", kicker: "Supervised-care limits", search: false, actions: [] },
  };

  seedIfEmpty();
  route = sanitizeRoute(route);
  bindEvents();
  hydrateFromRoute(route);
  render();
  if (!window.location.hash) navigate("overview", { replace: true, silent: true });

  function bindEvents() {
    loginForm.addEventListener("submit", (event) => {
      event.preventDefault();
      if (accessCode.value.trim() !== demoAccessCode) {
        loginError.textContent = "Use the workspace access code: leafstep-pro";
        return;
      }
      loginError.textContent = "";
      loginPanel.classList.add("hidden");
      appPanel.classList.remove("hidden");
      render();
      window.scrollTo({ top: 0, left: 0 });
    });

    window.addEventListener("hashchange", () => {
      route = sanitizeRoute(parseRoute(window.location.hash));
      hydrateFromRoute(route);
      render();
      window.scrollTo({ top: 0, left: 0 });
    });

    searchInput.addEventListener("input", () => {
      window.clearTimeout(searchTimer);
      searchTimer = window.setTimeout(() => {
        const key = activeSearchKey();
        if (!key) return;
        state.searchTerms[key] = searchInput.value.trim();
        state.pages[key] = 1;
        persist({ quiet: true });
        renderActiveSurface();
      }, 200);
    });

    document.addEventListener("input", (event) => {
      const target = event.target;
      if (!target.dataset.listSearch) return;
      window.clearTimeout(searchTimer);
      searchTimer = window.setTimeout(() => {
        const list = target.dataset.listSearch;
        const searchValue = target.value;
        state.searchTerms[list] = searchValue.trim();
        state.pages[list] = 1;
        persist({ quiet: true });
        renderActiveSurface();
        const nextInput = document.querySelector(`[data-list-search="${list}"]`);
        if (nextInput) {
          nextInput.focus();
          nextInput.setSelectionRange(searchValue.length, searchValue.length);
        }
      }, 200);
    });

    document.querySelectorAll("[data-view]").forEach((button) => {
      button.addEventListener("click", () => navigate(button.dataset.view));
    });

    document.querySelectorAll("[data-view-shortcut]").forEach((button) => {
      button.addEventListener("click", () => navigate(button.dataset.viewShortcut));
    });

    sidebarToggle.addEventListener("click", () => {
      sidebarCollapsed = !sidebarCollapsed;
      applySidebarState();
      persist();
    });

    document.querySelectorAll("[data-open-plan]").forEach((button) => {
      button.addEventListener("click", () => openPlanEditor());
    });

    document.querySelectorAll("[data-open-dish]").forEach((button) => {
      button.addEventListener("click", () => navigate("dish-library/new"));
    });

    document.querySelectorAll("[data-open-patient]").forEach((button) => {
      button.addEventListener("click", () => {
        navigate("patients");
        document.querySelector("#patient-form")?.reset();
        document.querySelector("#patient-plan").value = "";
        patientDialog.showModal();
        window.setTimeout(() => document.querySelector("#patient-label")?.focus(), 0);
      });
    });

    document.querySelector("#seed-plan")?.addEventListener("click", () => {
      const plan = samplePlan("balanced");
      plan.title = `Weekly Plan ${state.plans.length + 1}`;
      state.plans.push(plan);
      selectedPlanId = plan.id;
      persist();
      navigate("meal-plans", { silent: true });
      render();
    });

    document.querySelector("#reset-demo").addEventListener("click", () => {
      const seeded = seedState();
      state.dishes = seeded.dishes;
      state.plans = seeded.plans;
      state.patients = seeded.patients;
      state.codes = [];
      state.searchTerms = defaultSearchTerms();
      state.filters = defaultFilters();
      state.sorts = defaultSorts();
      state.pages = defaultPages();
      state.demoDataVersion = richDemoDataVersion;
      selectedPatientId = state.patients[0]?.id || null;
      selectedPlanId = state.plans[0]?.id || null;
      selectedDishId = state.dishes[0]?.id || null;
      persist();
      navigate("overview", { silent: true });
      render();
    });

    document.addEventListener("submit", handleSubmit);
    document.addEventListener("click", handleActionClick);
    document.addEventListener("change", handleChange);

    confirmCancel.addEventListener("click", () => confirmDialog.close());
    document.querySelectorAll("[data-close-patient]").forEach((button) => button.addEventListener("click", () => patientDialog.close()));
    document.querySelectorAll("[data-close-plan]").forEach((button) => button.addEventListener("click", () => planDialog.close()));
    document.querySelectorAll("[data-close-slot]").forEach((button) => button.addEventListener("click", () => slotDialog.close()));
    document.querySelectorAll("[data-close-pairing]").forEach((button) => button.addEventListener("click", () => pairingDialog.close()));
  }

  function handleSubmit(event) {
    if (event.target.id === "patient-form") {
      event.preventDefault();
      const label = value("#patient-label");
      if (!label) return;
      const planId = value("#patient-plan");
      const patient = {
        id: crypto.randomUUID(),
        label,
        activePlanId: planId,
        status: planId ? "ready" : "unassigned",
        createdAt: new Date().toISOString(),
      };
      state.patients.push(patient);
      selectedPatientId = patient.id;
      event.target.reset();
      patientDialog.close();
      persist();
      navigate(`patients/${patient.id}`, { silent: true });
      render();
    }

    if (event.target.id === "plan-form") {
      event.preventDefault();
      savePlanForm();
    }

    if (event.target.id === "slot-form") {
      event.preventDefault();
      saveSlotForm();
    }

    if (event.target.id === "dish-form") {
      event.preventDefault();
      saveDishForm(event.target);
    }
  }

  function handleActionClick(event) {
    const target = event.target.closest("[data-action]");
    if (!target) return;
    const { action, id } = target.dataset;

    if (action === "route") {
      navigate(target.dataset.route || "overview");
      return;
    }
    if (action === "select-patient") {
      selectedPatientId = id;
      navigate(`patients/${id}`);
      return;
    }
    if (action === "select-plan") {
      selectedPlanId = id;
      navigate(`meal-plans/${id}`);
      persist({ quiet: true });
      return;
    }
    if (action === "select-dish") {
      selectedDishId = id;
      navigate(`dish-library/${id}`);
      return;
    }
    if (action === "page-list") {
      state.pages[target.dataset.list] = Number(target.dataset.page) || 1;
      persist({ quiet: true });
      renderActiveSurface();
      return;
    }
    if (action === "open-plan") {
      openPlanEditor(findPlan(id));
      return;
    }
    if (action === "open-dish") {
      selectedDishId = id;
      navigate(`dish-library/${id}/edit`);
      return;
    }
    if (action === "new-dish-from-slot") {
      slotDialog.close();
      navigate("dish-library/new");
      return;
    }
    if (action === "duplicate-plan") {
      duplicatePlan(id);
      persist();
      navigate(`meal-plans/${selectedPlanId}`, { silent: true });
      render();
      return;
    }
    if (action === "duplicate-dish") {
      duplicateDish(id);
      persist();
      navigate(`dish-library/${selectedDishId}`, { silent: true });
      render();
      return;
    }
    if (action === "delete-plan") {
      confirmDeletePlan(id);
      return;
    }
    if (action === "delete-dish") {
      confirmDeleteDish(id);
      return;
    }
    if (action === "delete-patient") {
      confirmDeletePatient(id);
      return;
    }
    if (action === "build-patient-plan") {
      const patient = findPatient(id);
      selectedPatientId = id;
      if (patient?.activePlanId) {
        selectedPlanId = patient.activePlanId;
        navigate(`patients/${id}/plans/${patient.activePlanId}`);
        return;
      }
      openPlanEditor();
      return;
    }
    if (action === "add-slot") {
      openSlotEditor({ planId: id, day: target.dataset.day });
      return;
    }
    if (action === "edit-slot") {
      openSlotEditor({ planId: target.dataset.planId, slotId: id });
      return;
    }
    if (action === "delete-slot") {
      deleteSlot(target.dataset.planId, id);
      return;
    }
    if (action === "generate-code") {
      generateCode(id);
      return;
    }
    if (action === "view-code") {
      openPairingDialog(id);
      return;
    }
    if (action === "revoke-code") {
      confirmRevokeCode(id);
      return;
    }
    if (action === "copy-code") {
      copyCode(id, target);
      return;
    }
    if (action === "add-ingredient-row") {
      document.querySelector("#ingredient-rows")?.append(createIngredientRow());
      return;
    }
    if (action === "remove-ingredient-row") {
      target.closest(".ingredient-row")?.remove();
      return;
    }
    if (action === "cancel-dish-edit") {
      navigate(selectedDishId ? `dish-library/${selectedDishId}` : "dish-library");
    }
  }

  function handleChange(event) {
    const target = event.target;
    if (target.dataset.control) {
      const list = target.dataset.list;
      const key = target.dataset.control;
      if (key === "pageSize") {
        state.pageSize[list] = Number(target.value) || pageSizeDefault;
      } else if (key === "sort") {
        state.sorts[list] = target.value;
      } else {
        state.filters[list][key] = target.value;
      }
      state.pages[list] = 1;
      persist({ quiet: true });
      renderActiveSurface();
      return;
    }

    const actionTarget = target.closest("[data-action]");
    if (!actionTarget) return;
    if (actionTarget.dataset.action === "change-patient-plan") {
      const patient = findPatient(actionTarget.dataset.id);
      if (!patient) return;
      const planId = resolvePlanInput(`#${target.id}`) || "";
      patient.activePlanId = planId;
      patient.status = planId ? "ready" : "unassigned";
      revokeActiveCodesForPatient(patient.id);
      selectedPlanId = planId || selectedPlanId;
      persist();
      render();
    }
  }

  function render() {
    indexes = buildIndexes();
    route = sanitizeRoute(route);
    hydrateFromRoute(route);
    applySidebarState();
    renderShell();
    renderMetrics();
    renderPlanOptions();
    renderActiveSurface();
  }

  function renderActiveSurface() {
    indexes = buildIndexes();
    renderRoutePanels();
    if (route.view === "overview") renderOverview();
    if (route.view === "patients") {
      renderPatients();
      renderPatientDetail();
    }
    if (route.view === "meal-plans") {
      if (route.mode === "plan-detail") {
        renderPlanBoard({ scopedPatient: null });
      } else {
        renderPlans();
      }
    }
    if (route.view === "dish-library") {
      if (route.mode === "dish-list") {
        renderDishes();
      } else {
        renderDishDetail();
      }
    }
  }

  function renderShell() {
    const meta = viewMeta[route.view] || viewMeta.overview;
    const titleContext = titleForRoute(route);
    viewTitle.textContent = titleContext.title || meta.title;
    viewKicker.textContent = titleContext.kicker || meta.kicker;
    renderBreadcrumbs(titleContext.crumbs || []);

    const key = activeSearchKey();
    const searchMovesIntoList = ["patient-list", "plan-library", "dish-list"].includes(route.mode);
    const suppressDishDetailSearch = route.view === "dish-library" && route.mode !== "dish-list";
    searchWrapper.classList.toggle("is-hidden", !meta.search || searchMovesIntoList || suppressDishDetailSearch);
    searchLabel.textContent = meta.searchLabel || "Search workspace";
    if (meta.placeholder) searchInput.placeholder = meta.placeholder;
    if (key && document.activeElement !== searchInput) searchInput.value = state.searchTerms[key] || "";

    document.querySelector("#quick-patient-action").classList.toggle("is-hidden", !meta.actions.includes("patient"));
    document.querySelector("#quick-plan-action").classList.toggle("is-hidden", !meta.actions.includes("plan"));
    document.querySelector("#quick-dish-action").classList.toggle("is-hidden", !meta.actions.includes("dish"));

    document.querySelectorAll("[data-view]").forEach((button) => {
      const isActive = button.dataset.view === route.view;
      button.classList.toggle("active", isActive);
      button.setAttribute("aria-pressed", String(isActive));
    });
  }

  function renderRoutePanels() {
    document.querySelectorAll("[data-view-panel]").forEach((panel) => {
      const isActive = panel.dataset.viewPanel === route.view;
      panel.classList.toggle("active-view", isActive);
      panel.hidden = !isActive;
    });

    const patientPanel = document.querySelector("#patients");
    patientPanel.classList.toggle("focus-mode", route.mode === "patient-plan" || route.mode === "patient-detail");
    patientPanel.classList.toggle("list-mode", route.mode === "patient-list");
    const plannerPanel = document.querySelector(".planner-layout");
    plannerPanel?.classList.toggle("library-mode", route.mode !== "plan-detail");
    plannerPanel?.classList.toggle("detail-mode", route.mode === "plan-detail");
    const dishPanel = document.querySelector(".dish-layout");
    dishPanel?.classList.toggle("library-mode", route.mode === "dish-list");
    dishPanel?.classList.toggle("detail-mode", route.view === "dish-library" && route.mode !== "dish-list");
  }

  function renderBreadcrumbs(items) {
    breadcrumbs.classList.toggle("is-hidden", !items.length);
    if (!items.length) {
      breadcrumbs.innerHTML = "";
      return;
    }
    breadcrumbs.innerHTML = items.map((item, index) => {
      const isLast = index === items.length - 1;
      return isLast
        ? `<span aria-current="page">${escapeHtml(item.label)}</span>`
        : `<button type="button" data-action="route" data-route="${escapeAttribute(item.path.replace(/^#/, ""))}">${escapeHtml(item.label)}</button>`;
    }).join(`<span aria-hidden="true">/</span>`);
  }

  function renderMetrics() {
    if (route.view !== "overview") return;
    const activeCodes = activePairingCodes();
    const assignedPlans = state.patients.filter((patient) => patient.activePlanId).length;
    document.querySelector("#metric-grid").innerHTML = [
      metricCard("Patients", state.patients.length, `${assignedPlans} with an active plan`, "patients"),
      metricCard("Meal plans", state.plans.length, "Reusable weekly guidance", "plans"),
      metricCard("Dishes", state.dishes.length, "Saved for future plans", "dishes"),
      metricCard("Active pairings", activeCodes.length, "Patient app access links", "pairings"),
    ].join("");
  }

  function renderOverview() {
    const nextStepsPanel = document.querySelector(".next-steps-panel");
    const patientList = document.querySelector("#overview-patient-list");
    const activityList = document.querySelector("#overview-activity-list");
    const needsPlan = state.patients.filter((patient) => !patient.activePlanId).length;
    const readyToShare = state.patients.filter((patient) => patient.activePlanId && !latestCodeForPatient(patient.id)).length;
    const assignedPlans = state.plans.filter((plan) => indexes.patientsByPlan.get(plan.id)?.length).length;

    nextStepsPanel.innerHTML = `
      <div class="panel-head">
        <h3>Work queue</h3>
        <span class="pill">Start here</span>
      </div>
      <div class="overview-insights">
        <button class="overview-insight" type="button" data-action="route" data-route="patients">
          <span class="insight-kicker">${needsPlan} need setup</span>
          <strong>Finish patient planning</strong>
          <p>Assign a plan before sharing access.</p>
        </button>
        <button class="overview-insight" type="button" data-action="route" data-route="patients">
          <span class="insight-kicker">${readyToShare} ready</span>
          <strong>Share access when approved</strong>
          <p>Generate links only after the weekly agenda is ready.</p>
        </button>
        <button class="overview-insight" type="button" data-action="route" data-route="meal-plans">
          <span class="insight-kicker">${assignedPlans} assigned</span>
          <strong>Keep templates reusable</strong>
          <p>Use Meal Plans as the library, not the patient workflow.</p>
        </button>
      </div>
    `;

    patientList.innerHTML = "";
    activityList.innerHTML = "";

    const recentPatients = [...state.patients].sort(dateDesc).slice(0, 4);
    if (!recentPatients.length) {
      patientList.append(emptyRow("No patients yet", "Create a patient label to begin a supervised meal plan."));
    } else {
      recentPatients.forEach((patient) => {
        const plan = findPlan(patient.activePlanId);
        const row = document.createElement("article");
        row.className = "record-row";
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient.label)}</div>
            <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${patientStatusText(patient)}</p>
          </div>
          <button class="button subtle compact" type="button" data-action="select-patient" data-id="${patient.id}">Open profile</button>
        `;
        patientList.append(row);
      });
    }

    const recentCodes = [...state.codes].sort(dateDesc).slice(0, 4);
    if (!recentCodes.length) {
      activityList.append(emptyRow("No pairing activity", "Generate a pairing link from a patient when they are ready."));
    } else {
      recentCodes.forEach((code) => {
        const patient = findPatient(code.patientId);
        const row = document.createElement("article");
        row.className = "record-row";
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient?.label || "Removed patient")}</div>
            <p class="record-meta">${codeStatus(code)} · Expires ${formatDate(code.expiresAt)}</p>
          </div>
          <button class="button subtle compact" type="button" data-action="view-code" data-id="${code.id}">View link</button>
        `;
        activityList.append(row);
      });
    }
  }

  function renderPlanOptions() {
    fillPlanDatalist("#patient-plan-options");
    fillPlanSelect("#patient-plan");
  }

  function renderPatients() {
    const list = document.querySelector("#patient-list");
    const allPatients = sortPatients(filterPatients());
    const page = paginated("patients", allPatients);
    document.querySelector("#patient-count").textContent = `${page.items.length} of ${allPatients.length} shown`;
    renderPatientTools();
    list.innerHTML = "";
    if (!page.items.length) {
      list.append(emptyRow("No matching patients", "Adjust search, filters, or create a patient label."));
    } else {
      page.items.forEach((patient) => {
        const plan = findPlan(patient.activePlanId);
        const row = document.createElement("button");
        row.className = "record-row selectable";
        row.type = "button";
        row.dataset.action = "select-patient";
        row.dataset.id = patient.id;
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient.label)}</div>
            <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${patientStatusText(patient)}</p>
          </div>
          <span class="pill ${patient.activePlanId ? "blue" : "danger"}">${patient.activePlanId ? "Planned" : "Needs plan"}</span>
        `;
        list.append(row);
      });
    }
    renderPagination("patients", allPatients.length);
  }

  function renderPatientTools() {
    const planOptions = [`<option value="all">All plans</option>`, `<option value="none">No active plan</option>`]
      .concat(state.plans.map((plan) => `<option value="${plan.id}">${escapeHtml(plan.title)}</option>`))
      .join("");
    document.querySelector("#patient-tools").innerHTML = `
      ${toolbarSearch("patients", "Search", "Search patients or assigned plans")}
      <label><span>Plan</span>
        <select data-control="plan" data-list="patients">${planOptions}</select>
      </label>
      <label><span>Status</span>
        <select data-control="status" data-list="patients">
          <option value="all">All statuses</option>
          <option value="needs-plan">Needs plan</option>
          <option value="planned">Planned</option>
          <option value="pairing-active">Pairing active</option>
          <option value="paired">Paired</option>
        </select>
      </label>
      <label><span>Sort</span>
        <select data-control="sort" data-list="patients">
          <option value="created-desc">Newest</option>
          <option value="label-asc">Patient label A-Z</option>
          <option value="status-asc">Status</option>
        </select>
      </label>
      ${pageSizeSelect("patients")}
    `;
    setToolValues("patients");
  }

  function renderPatientDetail() {
    const panel = document.querySelector("#patient-detail");
    const patient = findPatient(selectedPatientId) || state.patients[0];
    if (!patient) {
      panel.innerHTML = detailEmpty("No patient selected", "Create a patient label to assign meal guidance.");
      return;
    }
    selectedPatientId = patient.id;
    const plan = findPlan(route.planId || patient.activePlanId);
    const activeCode = latestCodeForPatient(patient.id);
    const codeStatusText = activeCode ? codeStatus(activeCode) : "No active link";

    if (route.mode === "patient-plan") {
      panel.innerHTML = patientPlanEditor(patient, plan);
      return;
    }

    panel.innerHTML = `
      <div class="plan-detail-head">
        <div>
          <h3>${escapeHtml(patient.label)}</h3>
          <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${codeStatusText}</p>
        </div>
        <div class="record-actions">
          <button class="button tertiary compact" type="button" data-action="route" data-route="patients">Back to list</button>
          <span class="pill ${patient.activePlanId ? "blue" : "danger"}">${patient.activePlanId ? "Active" : "Needs plan"}</span>
        </div>
      </div>
      <div class="detail-stack">
        <label>
          Active plan
          <input id="patient-detail-plan-search" list="patient-detail-plan-options" value="${escapeAttribute(plan?.title || "")}" data-action="change-patient-plan" data-id="${patient.id}" placeholder="Search plans">
          <datalist id="patient-detail-plan-options">${planDatalistOptions()}</datalist>
        </label>
        <div class="patient-action-grid">
          <button class="button primary" type="button" data-action="build-patient-plan" data-id="${patient.id}">${patient.activePlanId ? "Build plan" : "Create plan"}</button>
          <button class="button subtle" type="button" data-action="generate-code" data-id="${patient.id}" ${patient.activePlanId ? "" : "disabled"}>Generate pairing link</button>
          ${activeCode ? `<button class="button subtle" type="button" data-action="view-code" data-id="${activeCode.id}">View link</button>` : ""}
          ${activeCode && codeStatus(activeCode) === "Active" ? `<button class="button danger" type="button" data-action="revoke-code" data-id="${activeCode.id}">Revoke</button>` : ""}
          <button class="button danger" type="button" data-action="delete-patient" data-id="${patient.id}">Delete patient</button>
        </div>
        <section class="plan-note">
          <strong>Patient labels only</strong>
          <p>Use internal labels like Patient 014. The prototype does not need names, emails, diagnosis, weight history, or app activity.</p>
        </section>
        ${plan ? patientPlanPreview(patient, plan) : ""}
      </div>
    `;
  }

  function patientPlanEditor(patient, plan) {
    if (!plan) return detailEmpty("No active plan", "Assign a meal plan before editing the weekly agenda.");
    selectedPlanId = plan.id;
    return `
      <section class="patient-plan-context">
        <div class="plan-detail-head">
          <div>
            <p class="record-meta">For ${escapeHtml(patient.label)}</p>
            <h3>${escapeHtml(plan.title)}</h3>
            <p class="record-meta">${escapeHtml(plan.effective)} · ${allSlots(plan).length} meals · Last updated ${formatDate(plan.updatedAt || plan.createdAt)}</p>
          </div>
          <div class="record-actions">
            <button class="button subtle" type="button" data-action="open-plan" data-id="${plan.id}">Edit details</button>
            <button class="button subtle" type="button" data-action="duplicate-plan" data-id="${plan.id}">Duplicate</button>
          </div>
        </div>
        <p class="plan-note">${escapeHtml(plan.note || "Add saved dishes to the weekly agenda.")}</p>
        ${weeklyAgenda(plan)}
      </section>
    `;
  }

  function patientPlanPreview(patient, plan) {
    const slots = allSlots(plan).slice(0, 5);
    return `
      <section class="dish-detail-section">
        <div class="panel-head">
          <h4>Active plan preview</h4>
          <button class="button subtle" type="button" data-action="build-patient-plan" data-id="${patient.id}">Open weekly agenda</button>
        </div>
        ${slots.length ? slots.map((slot) => {
          const dish = findDish(slot.dishId);
          return `<p class="record-meta">${escapeHtml(slot.day)} · ${escapeHtml(slot.meal)} · ${escapeHtml(dish?.title || "Dish")}</p>`;
        }).join("") : `<p class="record-meta">No meals added yet.</p>`}
      </section>
    `;
  }

  function renderPlans() {
    const list = document.querySelector("#plan-list");
    const allPlans = sortPlans(filterPlans());
    const page = paginated("plans", allPlans);
    document.querySelector("#plan-count").textContent = `${page.items.length} of ${allPlans.length} shown`;
    renderPlanTools();
    list.innerHTML = "";
    if (!page.items.length) {
      list.append(emptyRow("No matching plans", "Create a weekly plan or clear search."));
    } else {
      page.items.forEach((plan) => {
        const assignments = indexes.patientsByPlan.get(plan.id)?.length || 0;
        const slotCount = allSlots(plan).length;
        const mealLabel = slotCount === 1 ? "meal" : "meals";
        const patientLabel = assignments === 1 ? "patient" : "patients";
        const row = document.createElement("button");
        row.className = "record-row selectable plan-library-row";
        row.type = "button";
        row.dataset.action = "select-plan";
        row.dataset.id = plan.id;
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(plan.title)}</div>
            <p class="record-meta">${escapeHtml(plan.effective)} · Updated ${formatDate(plan.updatedAt || plan.createdAt)}</p>
          </div>
          <div class="plan-row-stats">
            <span class="pill">${assignments ? "Assigned" : "Draft"}</span>
            <span>${slotCount} ${mealLabel}</span>
            <span>${assignments} ${patientLabel}</span>
          </div>
        `;
        list.append(row);
      });
    }
    renderPagination("plans", allPlans.length);
  }

  function renderPlanTools() {
    document.querySelector("#plan-tools").innerHTML = `
      ${toolbarSearch("plans", "Search", "Search meal plans")}
      <label><span>Status</span>
        <select data-control="status" data-list="plans">
          <option value="all">All plans</option>
          <option value="assigned">Assigned</option>
          <option value="draft">Draft</option>
        </select>
      </label>
      <label><span>Sort</span>
        <select data-control="sort" data-list="plans">
          <option value="updated-desc">Recently updated</option>
          <option value="title-asc">Title A-Z</option>
          <option value="assigned-desc">Most assigned</option>
          <option value="meals-desc">Most meals</option>
          <option value="patients-desc">Most patients</option>
        </select>
      </label>
      ${pageSizeSelect("plans")}
    `;
    setToolValues("plans");
  }

  function renderPlanBoard({ scopedPatient }) {
    const panel = document.querySelector("#plan-board-panel");
    const plan = findPlan(route.planId || selectedPlanId) || state.plans[0];
    if (!plan) {
      panel.innerHTML = detailEmpty("No plan selected", "Create a weekly meal plan to add dishes.");
      return;
    }
    selectedPlanId = plan.id;
    const assignments = indexes.patientsByPlan.get(plan.id)?.length || 0;
    panel.innerHTML = `
      <div class="plan-detail-head">
        <div>
          <h3>${escapeHtml(plan.title)}</h3>
          <p class="record-meta">${escapeHtml(plan.effective)} · ${assignments} patients · Last updated ${formatDate(plan.updatedAt || plan.createdAt)}</p>
        </div>
        <div class="record-actions">
          ${route.mode === "plan-detail" ? `<button class="button tertiary" type="button" data-action="route" data-route="meal-plans">Back to library</button>` : ""}
          <button class="button subtle" type="button" data-action="open-plan" data-id="${plan.id}">Edit details</button>
          <button class="button subtle" type="button" data-action="duplicate-plan" data-id="${plan.id}">Duplicate</button>
          <button class="button danger" type="button" data-action="delete-plan" data-id="${plan.id}">Delete</button>
        </div>
      </div>
      <p class="plan-note">${escapeHtml(plan.note || "Add saved dishes to the weekly agenda.")}</p>
      ${weeklyAgenda(plan, scopedPatient)}
    `;
  }

  function weeklyAgenda(plan) {
    return `
      <div class="week-agenda">
        ${days.map((dayName, index) => dayAgenda(plan, dayName, index)).join("")}
      </div>
    `;
  }

  function dayAgenda(plan, dayName, index) {
    const day = ensureDay(plan, dayName);
    const grouped = groupSlots(day.slots || []);
    return `
      <section class="agenda-day day-tone-${index % days.length}">
        <div class="agenda-day-head">
          <div>
            <h4>${escapeHtml(dayName)}</h4>
            <p class="record-meta">${day.slots.length || 0} meals planned</p>
          </div>
          <button class="button subtle" type="button" data-action="add-slot" data-id="${plan.id}" data-day="${dayName}">Add meal</button>
        </div>
        <div class="agenda-meals">
          ${mealGroups.map((mealName) => mealLane(plan.id, dayName, mealName, grouped.get(mealName) || [])).join("")}
          ${(grouped.get("Other") || []).length ? mealLane(plan.id, dayName, "Other", grouped.get("Other")) : ""}
        </div>
      </section>
    `;
  }

  function mealLane(planId, dayName, mealName, slots) {
    return `
      <section class="agenda-meal-lane">
        <div class="meal-lane-title">
          <strong>${escapeHtml(mealName)}</strong>
          <button class="button subtle" type="button" data-action="add-slot" data-id="${planId}" data-day="${dayName}">Add</button>
        </div>
        <div class="slot-list">
          ${slots.length ? slots.map((slot) => slotCard(planId, slot)).join("") : `<p class="empty-inline">No ${escapeHtml(mealName.toLowerCase())} yet.</p>`}
        </div>
      </section>
    `;
  }

  function slotCard(planId, slot) {
    const dish = findDish(slot.dishId);
    return `
      <details class="slot-card">
        <summary class="slot-card-summary">
          <img src="${escapeAttribute(dish?.photo || dishPhotos[0].value)}" alt="">
          <div>
            <span>${escapeHtml(slot.time || "Anytime")}</span>
            <strong>${escapeHtml(dish?.title || "Saved dish")}</strong>
          </div>
        </summary>
        <div class="slot-card-more">
          <p>${escapeHtml(slot.note || dish?.portionGuidance || "Nutritionist-authored dish guidance.")}</p>
          <div class="mini-tags">${(dish?.tags || []).slice(0, 3).map((tag) => `<span>${escapeHtml(tag)}</span>`).join("")}</div>
          <div class="record-actions">
            <button class="button subtle" type="button" data-action="edit-slot" data-id="${slot.id}" data-plan-id="${planId}">Edit</button>
            <button class="button danger" type="button" data-action="delete-slot" data-id="${slot.id}" data-plan-id="${planId}">Remove</button>
          </div>
        </div>
      </details>
    `;
  }

  function renderDishes() {
    const list = document.querySelector("#dish-list");
    const allDishes = sortDishes(filterDishes());
    const page = paginated("dishes", allDishes);
    document.querySelector("#dish-count").textContent = `${page.items.length} of ${allDishes.length} shown`;
    renderDishTools();
    list.innerHTML = "";
    if (!page.items.length) {
      list.append(emptyRow("No matching dishes", "Create a dish or clear the search/filter."));
    } else {
      page.items.forEach((dish) => {
        const usedIn = indexes.dishUsage.get(dish.id) || 0;
        const usageLabel = usedIn === 1 ? "plan" : "plans";
        const row = document.createElement("button");
        row.className = "record-row selectable dish-library-row";
        row.type = "button";
        row.dataset.action = "select-dish";
        row.dataset.id = dish.id;
        row.innerHTML = `
          <div class="dish-row-main">
            <img src="${escapeAttribute(dish.photo)}" alt="">
            <div>
              <div class="record-title">${escapeHtml(dish.title)}</div>
              <p class="record-meta">${escapeHtml(dishSummaryTags(dish).join(" · ") || "No tags")} · Updated ${formatDate(dish.updatedAt || dish.createdAt)}</p>
            </div>
          </div>
          <div class="plan-row-stats dish-row-stats">
            <span>${usedIn} ${usageLabel}</span>
            ${dishStatTags(dish).map((tag) => `<span class="pill">${escapeHtml(tag)}</span>`).join("")}
          </div>
        `;
        list.append(row);
      });
    }
    renderPagination("dishes", allDishes.length);
  }

  function renderDishTools() {
    const otherTags = otherDishTags();
    document.querySelector("#dish-tools").innerHTML = `
      ${toolbarSearch("dishes", "Search", "Search dishes")}
      ${dishFilterSelect("meal")}
      ${dishFilterSelect("nutrition")}
      ${dishFilterSelect("prep")}
      ${dishFilterSelect("cuisine")}
      ${otherTags.length ? dishFilterSelect("other", otherTags) : ""}
      <label><span>Sort</span>
        <select data-control="sort" data-list="dishes">
          <option value="updated-desc">Recently updated</option>
          <option value="title-asc">Title A-Z</option>
          <option value="used-desc">Most used</option>
        </select>
      </label>
      ${pageSizeSelect("dishes")}
    `;
    setToolValues("dishes");
  }

  function renderDishDetail() {
    const panel = document.querySelector("#dish-detail");
    if (route.mode === "dish-list") {
      panel.innerHTML = "";
      return;
    }
    if (route.mode === "dish-new") {
      selectedDishId = null;
      panel.innerHTML = dishEditor();
      return;
    }
    const dish = findDish(route.dishId || selectedDishId) || state.dishes[0];
    if (!dish) {
      panel.innerHTML = detailEmpty("No dish selected", "Create reusable dishes to build meal plans faster.");
      return;
    }
    selectedDishId = dish.id;
    if (route.mode === "dish-edit") {
      panel.innerHTML = dishEditor(dish);
      return;
    }
    const usedIn = indexes.dishUsage.get(dish.id) || 0;
    panel.innerHTML = `
      <div class="plan-detail-head dish-detail-head">
        <div class="dish-detail-hero">
          <img src="${escapeAttribute(dish.photo)}" alt="">
          <div>
            <h3>${escapeHtml(dish.title)}</h3>
            <p class="record-meta">${usedIn} meal plans · Updated ${formatDate(dish.updatedAt || dish.createdAt)}</p>
          </div>
        </div>
        <div class="record-actions">
          <button class="button tertiary" type="button" data-action="route" data-route="dish-library">Back to library</button>
          <button class="button subtle" type="button" data-action="open-dish" data-id="${dish.id}">Edit</button>
          <button class="button subtle" type="button" data-action="duplicate-dish" data-id="${dish.id}">Duplicate</button>
          <button class="button danger" type="button" data-action="delete-dish" data-id="${dish.id}">Delete</button>
        </div>
      </div>
      <div class="dish-detail-body">
        <div>
          <div class="mini-tags">${(dish.tags || []).map((tag) => `<span>${escapeHtml(tag)}</span>`).join("")}</div>
          <section class="dish-detail-section">
            <h4>Ingredients</h4>
            <ul>${dish.ingredients.length ? dish.ingredients.map((ingredient) => `<li>${escapeHtml(formatIngredient(ingredient))}</li>`).join("") : "<li>No ingredients listed.</li>"}</ul>
          </section>
        </div>
        <div>
          <section class="dish-detail-section">
            <h4>Preparation</h4>
            <p>${escapeHtml(dish.preparation || "No preparation method added.")}</p>
          </section>
          <section class="dish-detail-section">
            <h4>Portions and swaps</h4>
            <p>${escapeHtml(dish.portionGuidance || "Use nutritionist-written portion guidance.")}</p>
            <p class="record-meta">${escapeHtml((dish.swaps || []).join(" · ") || "No swaps listed.")}</p>
          </section>
        </div>
      </div>
    `;
  }

  function dishEditor(dish = null) {
    const selectedTags = dish?.tags || [];
    const ingredients = dish?.ingredients?.length ? dish.ingredients : [{ amount: "", unit: "", item: "", note: "" }];
    return `
      <form id="dish-form" class="screen-form">
        <div class="plan-detail-head">
          <div>
            <p class="topline">Dish library</p>
            <h3>${dish ? "Edit dish" : "Create dish"}</h3>
            <p class="record-meta">Reusable dishes stay available for every weekly plan.</p>
          </div>
          <div class="record-actions">
            <button class="button tertiary" type="button" data-action="cancel-dish-edit">Cancel</button>
            <button class="button primary" type="submit">Save dish</button>
          </div>
        </div>
        <input id="dish-id" type="hidden" value="${escapeAttribute(dish?.id || "")}">
        <div class="dish-editor-grid">
          <section class="dish-editor-main">
            <div class="form-grid">
              <label>Dish title
                <input id="dish-title" value="${escapeAttribute(dish?.title || "")}" placeholder="Chicken Salad Bowl" required>
              </label>
              <label>Photo
                <select id="dish-photo" required>${photoOptions(dish?.photo)}</select>
              </label>
              <label class="full">Preset tags
                <div id="dish-tag-options" class="tag-check-grid">${tagChecks(selectedTags)}</div>
              </label>
              <label class="full">Custom tags
                <input id="dish-custom-tags" value="${escapeAttribute(selectedTags.filter((tag) => !presetTags.includes(tag)).join(", "))}" placeholder="anti-inflammatory, family dinner">
              </label>
              <label class="full">Portion guidance
                <textarea id="dish-portion" rows="2" placeholder="Use the portion guide discussed with the patient.">${escapeHtml(dish?.portionGuidance || "")}</textarea>
              </label>
              <label class="full">Preparation method
                <textarea id="dish-preparation" rows="4" placeholder="Step-by-step preparation guidance.">${escapeHtml(dish?.preparation || "")}</textarea>
              </label>
              <label class="full">Swaps
                <textarea id="dish-swaps" rows="2" placeholder="Swap chicken for tofu or tuna.">${escapeHtml((dish?.swaps || []).join("\n"))}</textarea>
              </label>
              <label class="full">Notes
                <textarea id="dish-notes" rows="2" placeholder="Optional nutritionist note.">${escapeHtml(dish?.notes || "")}</textarea>
              </label>
            </div>
          </section>
          <section class="dish-editor-side">
            <div class="panel-head">
              <h3>Ingredients</h3>
              <button class="button subtle" type="button" data-action="add-ingredient-row">Add ingredient</button>
            </div>
            <div id="ingredient-rows" class="ingredient-rows">
              ${ingredients.map((ingredient) => ingredientRowMarkup(ingredient)).join("")}
            </div>
          </section>
        </div>
        <div class="form-bottom-actions">
          <button class="button tertiary" type="button" data-action="cancel-dish-edit">Cancel</button>
          <button class="button primary" type="submit">Save dish</button>
        </div>
      </form>
    `;
  }

  function savePlanForm() {
    const id = document.querySelector("#plan-id").value;
    const plan = id ? findPlan(id) : null;
    const next = {
      id: id || crypto.randomUUID(),
      title: value("#plan-title") || "Untitled meal plan",
      effective: value("#plan-effective") || "This week",
      note: value("#plan-note"),
      days: plan?.days || emptyWeek(),
      createdAt: plan?.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    if (id) {
      state.plans = state.plans.map((item) => item.id === id ? next : item);
    } else {
      state.plans.push(next);
      if (selectedPatientId && route.view === "patients") {
        const patient = findPatient(selectedPatientId);
        if (patient && !patient.activePlanId) patient.activePlanId = next.id;
      }
    }
    selectedPlanId = next.id;
    persist();
    planDialog.close();
    render();
  }

  function saveSlotForm() {
    const plan = findPlan(document.querySelector("#slot-plan-id").value);
    if (!plan) return;
    const dishId = resolveDishInput("#slot-dish-search");
    if (!dishId) {
      showSaveStatus("Choose a saved dish first.", "error");
      return;
    }
    const slotId = document.querySelector("#slot-id").value || crypto.randomUUID();
    const slot = {
      id: slotId,
      day: document.querySelector("#slot-day").value,
      meal: value("#slot-meal") || "Meal",
      time: value("#slot-time"),
      dishId,
      note: value("#slot-note"),
    };
    const day = ensureDay(plan, slot.day);
    day.slots = day.slots.filter((item) => item.id !== slotId);
    day.slots.push(slot);
    day.slots.sort((a, b) => (a.time || "").localeCompare(b.time || ""));
    plan.updatedAt = new Date().toISOString();
    selectedPlanId = plan.id;
    state.lastUsedDishIds = rememberId(state.lastUsedDishIds, dishId);
    persist();
    slotDialog.close();
    render();
  }

  function saveDishForm(form) {
    const id = form.querySelector("#dish-id").value;
    const source = id ? findDish(id) : null;
    const dish = {
      id: id || crypto.randomUUID(),
      title: value("#dish-title") || "Untitled dish",
      photo: document.querySelector("#dish-photo").value,
      tags: readDishTags(),
      ingredients: readIngredientRows(),
      preparation: value("#dish-preparation"),
      portionGuidance: value("#dish-portion"),
      swaps: linesFromText(value("#dish-swaps")),
      notes: value("#dish-notes"),
      createdAt: source?.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    if (id) {
      state.dishes = state.dishes.map((item) => item.id === id ? dish : item);
    } else {
      state.dishes.push(dish);
    }
    selectedDishId = dish.id;
    state.lastUsedDishIds = rememberId(state.lastUsedDishIds, dish.id);
    persist();
    navigate(`dish-library/${dish.id}`, { silent: true });
    render();
  }

  function openPlanEditor(plan = null) {
    document.querySelector("#plan-dialog-title").textContent = plan ? "Edit plan" : "Create plan";
    document.querySelector("#plan-id").value = plan?.id || "";
    document.querySelector("#plan-title").value = plan?.title || "";
    document.querySelector("#plan-effective").value = plan?.effective || "";
    document.querySelector("#plan-note").value = plan?.note || "";
    planDialog.showModal();
  }

  function openSlotEditor({ planId, day, slotId }) {
    const plan = findPlan(planId);
    if (!plan) return;
    const slot = slotId ? allSlots(plan).find((item) => item.id === slotId) : null;
    document.querySelector("#slot-dialog-title").textContent = slot ? "Edit meal slot" : "Add meal slot";
    document.querySelector("#slot-plan-id").value = plan.id;
    document.querySelector("#slot-id").value = slot?.id || "";
    fillDayOptions("#slot-day", slot?.day || day || days[0]);
    document.querySelector("#slot-meal").value = slot?.meal || "";
    document.querySelector("#slot-time").value = slot?.time || "";
    document.querySelector("#slot-note").value = slot?.note || "";
    fillSlotDishPicker(slot?.dishId || state.lastUsedDishIds[0] || state.dishes[0]?.id || "");
    slotDialog.showModal();
  }

  function createIngredientRow(ingredient = {}) {
    const template = document.createElement("template");
    template.innerHTML = ingredientRowMarkup(ingredient).trim();
    return template.content.firstElementChild;
  }

  function ingredientRowMarkup(ingredient = {}) {
    return `
      <div class="ingredient-row">
        <label>Amount
          <input name="amount" placeholder="1" value="${escapeAttribute(ingredient.amount || "")}">
        </label>
        <label>Unit
          <input name="unit" placeholder="cup" value="${escapeAttribute(ingredient.unit || "")}">
        </label>
        <label>Ingredient
          <input name="item" placeholder="greens" value="${escapeAttribute(ingredient.item || "")}" required>
        </label>
        <label>Note
          <input name="note" placeholder="chopped" value="${escapeAttribute(ingredient.note || "")}">
        </label>
        <button class="remove-meal" type="button" data-action="remove-ingredient-row" aria-label="Remove ingredient row">-</button>
      </div>
    `;
  }

  function readIngredientRows() {
    return [...document.querySelectorAll("#ingredient-rows .ingredient-row")]
      .map((row) => ({
        amount: row.querySelector('[name="amount"]').value.trim(),
        unit: row.querySelector('[name="unit"]').value.trim(),
        item: row.querySelector('[name="item"]').value.trim(),
        note: row.querySelector('[name="note"]').value.trim(),
      }))
      .filter((ingredient) => ingredient.item);
  }

  function readDishTags() {
    const checked = [...document.querySelectorAll("#dish-tag-options input:checked")].map((input) => input.value);
    const custom = splitTags(value("#dish-custom-tags"));
    return uniqueTags([...checked, ...custom]);
  }

  function fillDayOptions(selector, selectedDay) {
    const select = document.querySelector(selector);
    select.innerHTML = days.map((dayName) => `<option value="${dayName}" ${dayName === selectedDay ? "selected" : ""}>${dayName}</option>`).join("");
  }

  function fillPlanDatalist(selector) {
    const datalist = document.querySelector(selector);
    if (!datalist) return;
    datalist.innerHTML = planDatalistOptions();
  }

  function fillPlanSelect(selector) {
    const select = document.querySelector(selector);
    if (!select) return;
    select.innerHTML = [
      `<option value="">No active plan yet</option>`,
      ...state.plans.map((plan) => `<option value="${escapeAttribute(plan.id)}">${escapeHtml(plan.title)}</option>`),
    ].join("");
  }

  function planDatalistOptions() {
    return state.plans.map((plan) => `<option value="${escapeAttribute(plan.title)}"></option>`).join("");
  }

  function fillSlotDishPicker(selectedDishId) {
    const input = document.querySelector("#slot-dish-search");
    const hidden = document.querySelector("#slot-dish");
    const datalist = document.querySelector("#slot-dish-options");
    const selectedDish = findDish(selectedDishId);
    input.value = selectedDish?.title || "";
    hidden.value = selectedDish?.id || "";
    datalist.innerHTML = state.dishes
      .map((dish) => `<option value="${escapeAttribute(dish.title)}"></option>`)
      .join("");
  }

  function resolvePlanInput(selector) {
    const input = document.querySelector(selector);
    const typed = input?.value.trim().toLowerCase() || "";
    if (!typed) return "";
    return state.plans.find((plan) => plan.title.toLowerCase() === typed)?.id || "";
  }

  function resolveDishInput(selector) {
    const input = document.querySelector(selector);
    const typed = input?.value.trim().toLowerCase() || "";
    if (!typed) return "";
    return state.dishes.find((dish) => dish.title.toLowerCase() === typed)?.id || "";
  }

  function duplicatePlan(id) {
    const plan = findPlan(id);
    if (!plan) return;
    const copy = {
      ...structuredClone(plan),
      id: crypto.randomUUID(),
      title: `${plan.title} copy`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    state.plans.push(copy);
    selectedPlanId = copy.id;
  }

  function duplicateDish(id) {
    const dish = findDish(id);
    if (!dish) return;
    const copy = {
      ...structuredClone(dish),
      id: crypto.randomUUID(),
      title: `${dish.title} copy`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    state.dishes.push(copy);
    selectedDishId = copy.id;
  }

  function confirmDeletePlan(id) {
    requestConfirm({
      title: "Delete this meal plan?",
      body: "This removes the weekly plan and unassigns it from any patients. Existing pairing links for the plan are revoked.",
      actionLabel: "Delete plan",
      onConfirm: () => {
        state.plans = state.plans.filter((plan) => plan.id !== id);
        state.patients.forEach((patient) => {
          if (patient.activePlanId === id) patient.activePlanId = "";
        });
        state.codes = state.codes.map((code) => code.planId === id ? revokedCopy(code) : code);
        selectedPlanId = state.plans[0]?.id || null;
        persist();
        navigate("meal-plans", { silent: true });
        render();
      },
    });
  }

  function confirmDeleteDish(id) {
    const useCount = indexes.dishUsage.get(id) || 0;
    requestConfirm({
      title: "Delete this dish?",
      body: useCount ? "This dish is used in meal plans. Deleting it removes those meal slots." : "This removes the reusable dish from the library.",
      actionLabel: "Delete dish",
      onConfirm: () => {
        state.dishes = state.dishes.filter((dish) => dish.id !== id);
        state.plans.forEach((plan) => {
          plan.days.forEach((day) => {
            day.slots = day.slots.filter((slot) => slot.dishId !== id);
          });
        });
        selectedDishId = state.dishes[0]?.id || null;
        persist();
        navigate(selectedDishId ? `dish-library/${selectedDishId}` : "dish-library", { silent: true });
        render();
      },
    });
  }

  function confirmDeletePatient(id) {
    requestConfirm({
      title: "Delete this patient?",
      body: "This removes the patient label and revokes any pairing link for it.",
      actionLabel: "Delete patient",
      onConfirm: () => {
        state.patients = state.patients.filter((patient) => patient.id !== id);
        state.codes = state.codes.map((code) => code.patientId === id ? revokedCopy(code) : code);
        selectedPatientId = state.patients[0]?.id || null;
        persist();
        navigate(selectedPatientId ? `patients/${selectedPatientId}` : "patients", { silent: true });
        render();
      },
    });
  }

  function deleteSlot(planId, slotId) {
    const plan = findPlan(planId);
    if (!plan) return;
    plan.days.forEach((day) => {
      day.slots = day.slots.filter((slot) => slot.id !== slotId);
    });
    plan.updatedAt = new Date().toISOString();
    persist();
    render();
  }

  function generateCode(patientId) {
    const patient = findPatient(patientId);
    if (!patient?.activePlanId) return;
    revokeActiveCodesForPatient(patient.id);
    const code = {
      id: crypto.randomUUID(),
      patientId: patient.id,
      planId: patient.activePlanId,
      token: shortToken(),
      status: "active",
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      revokedAt: null,
    };
    state.codes.push(code);
    patient.status = "invited";
    persist();
    render();
    openPairingDialog(code.id);
  }

  function confirmRevokeCode(id) {
    requestConfirm({
      title: "Revoke this pairing link?",
      body: "This stops the current link. You can generate a new link from the patient workspace.",
      actionLabel: "Revoke link",
      onConfirm: () => {
        const code = findCode(id);
        if (code) Object.assign(code, revokedCopy(code));
        if (pairingDialog.open) pairingDialog.close();
        persist();
        render();
      },
    });
  }

  async function copyCode(id, target) {
    const code = findCode(id);
    if (!code) return;
    await navigator.clipboard.writeText(pairingPayload(code));
    target.textContent = "Copied";
    window.setTimeout(() => {
      target.textContent = "Copy pairing link";
    }, 1400);
  }

  function openPairingDialog(codeId) {
    const code = findCode(codeId);
    if (!code) return;
    const patient = findPatient(code.patientId);
    const plan = findPlan(code.planId);
    const payload = pairingPayload(code);
    document.querySelector("#pairing-dialog-body").innerHTML = `
      <div class="pairing-card">
        <div class="qr-preview" aria-hidden="true">${qrPreviewMarkup(code.token)}</div>
        <div>
          <p class="record-meta">One-time link · ${codeStatus(code)} · expires ${formatDate(code.expiresAt)}</p>
          <h3>${escapeHtml(patient?.label || "Removed patient")}</h3>
          <p>${escapeHtml(plan?.title || "Assigned meal plan")}</p>
          <p>This grants read-only meal plan access in the Leafstep app.</p>
          <details class="secure-link-details">
            <summary>Show pairing link</summary>
            <code class="payload-box">${escapeHtml(payload)}</code>
          </details>
          <div class="pairing-actions">
            <button class="button primary" type="button" data-action="copy-code" data-id="${code.id}">Copy pairing link</button>
            <button class="button danger" type="button" data-action="revoke-code" data-id="${code.id}" ${codeStatus(code) === "Active" ? "" : "disabled"}>Revoke link</button>
          </div>
        </div>
      </div>
    `;
    pairingDialog.showModal();
  }

  function navigate(path, options = {}) {
    const nextHash = `#${path.replace(/^#/, "")}`;
    if (options.replace) {
      history.replaceState(null, "", nextHash);
    } else if (window.location.hash !== nextHash) {
      window.location.hash = nextHash;
    }
    route = sanitizeRoute(parseRoute(nextHash));
    hydrateFromRoute(route);
    if (!options.silent) render();
  }

  function parseRoute(hash) {
    const parts = String(hash || "").replace(/^#\/?/, "").split("/").filter(Boolean);
    if (!parts.length) return { view: "overview", mode: "overview" };
    if (parts[0] === "patients" && parts[1] && parts[2] === "plans" && parts[3]) {
      return { view: "patients", mode: "patient-plan", patientId: parts[1], planId: parts[3] };
    }
    if (parts[0] === "patients" && parts[1]) return { view: "patients", mode: "patient-detail", patientId: parts[1] };
    if (parts[0] === "patients") return { view: "patients", mode: "patient-list" };
    if (parts[0] === "dish-library" && parts[1] === "new") return { view: "dish-library", mode: "dish-new" };
    if (parts[0] === "dish-library" && parts[1] && parts[2] === "edit") return { view: "dish-library", mode: "dish-edit", dishId: parts[1] };
    if (parts[0] === "dish-library" && parts[1]) return { view: "dish-library", mode: "dish-detail", dishId: parts[1] };
    if (parts[0] === "dish-library") return { view: "dish-library", mode: "dish-list" };
    if (parts[0] === "meal-plans" && parts[1]) return { view: "meal-plans", mode: "plan-detail", planId: parts[1] };
    if (parts[0] === "meal-plans") return { view: "meal-plans", mode: "plan-library" };
    if (parts[0] === "privacy") return { view: "privacy", mode: "privacy" };
    return { view: "overview", mode: "overview" };
  }

  function sanitizeRoute(next) {
    if (next.patientId && !findPatient(next.patientId)) return { view: "patients", mode: "patient-list" };
    if (next.planId && !findPlan(next.planId)) {
      return next.patientId
        ? { view: "patients", mode: "patient-detail", patientId: next.patientId }
        : { view: "meal-plans", mode: "plan-library" };
    }
    if (next.dishId && !findDish(next.dishId)) return { view: "dish-library", mode: "dish-list" };
    return next;
  }

  function hydrateFromRoute(next) {
    if (next.patientId) selectedPatientId = next.patientId;
    if (next.planId) selectedPlanId = next.planId;
    if (next.dishId) selectedDishId = next.dishId;
    state.route = routePath(next);
    state.selectedPatientId = selectedPatientId;
    state.selectedPlanId = selectedPlanId;
    state.selectedDishId = selectedDishId;
  }

  function routePath(next) {
    if (next.mode === "patient-plan") return `patients/${next.patientId}/plans/${next.planId}`;
    if (next.mode === "patient-detail") return `patients/${next.patientId}`;
    if (next.mode === "plan-detail") return `meal-plans/${next.planId}`;
    if (next.mode === "dish-new") return "dish-library/new";
    if (next.mode === "dish-edit") return `dish-library/${next.dishId}/edit`;
    if (next.mode === "dish-detail") return `dish-library/${next.dishId}`;
    return next.view;
  }

  function titleForRoute(next) {
    if (next.mode === "patient-detail") {
      const patient = findPatient(next.patientId);
      return {
        title: patient?.label || "Patient",
        kicker: "Patient planning",
        crumbs: [{ label: "Patients", path: "#patients" }, { label: patient?.label || "Patient", path: `#patients/${next.patientId}` }],
      };
    }
    if (next.mode === "patient-plan") {
      const patient = findPatient(next.patientId);
      const plan = findPlan(next.planId);
      return {
        title: plan?.title || "Weekly plan",
        kicker: patient?.label || "Patient plan",
        crumbs: [
          { label: "Patients", path: "#patients" },
          { label: patient?.label || "Patient", path: `#patients/${next.patientId}` },
          { label: plan?.title || "Weekly plan", path: `#patients/${next.patientId}/plans/${next.planId}` },
        ],
      };
    }
    if (next.mode === "plan-detail") {
      const plan = findPlan(next.planId);
      return {
        title: plan?.title || "Meal plan",
        kicker: "Weekly agenda",
        crumbs: [{ label: "Meal Plans", path: "#meal-plans" }, { label: plan?.title || "Meal plan", path: `#meal-plans/${next.planId}` }],
      };
    }
    if (next.mode === "dish-new") {
      return { title: "Create dish", kicker: "Dish library", crumbs: [{ label: "Dish Library", path: "#dish-library" }, { label: "Create dish", path: "#dish-library/new" }] };
    }
    if (next.mode === "dish-edit") {
      const dish = findDish(next.dishId);
      return { title: "Edit dish", kicker: "Dish library", crumbs: [{ label: "Dish Library", path: "#dish-library" }, { label: dish?.title || "Dish", path: `#dish-library/${next.dishId}` }, { label: "Edit", path: `#dish-library/${next.dishId}/edit` }] };
    }
    if (next.mode === "dish-detail") {
      const dish = findDish(next.dishId);
      return { title: dish?.title || "Dish", kicker: "Dish library", crumbs: [{ label: "Dish Library", path: "#dish-library" }, { label: dish?.title || "Dish", path: `#dish-library/${next.dishId}` }] };
    }
    return { title: viewMeta[next.view]?.title, kicker: viewMeta[next.view]?.kicker, crumbs: [] };
  }

  function activeSearchKey() {
    return viewMeta[route.view]?.searchKey || null;
  }

  function filterPatients() {
    const term = state.searchTerms.patients;
    return state.patients.filter((patient) => {
      const plan = findPlan(patient.activePlanId);
      const planFilter = state.filters.patients.plan;
      const statusFilter = state.filters.patients.status;
      const planMatch = planFilter === "all" || (planFilter === "none" ? !patient.activePlanId : patient.activePlanId === planFilter);
      const statusMatch = statusFilter === "all" || patientMatchesStatus(patient, statusFilter);
      return planMatch && statusMatch && matchesSearch([patient.label, plan?.title || "", patientStatusText(patient)], term);
    });
  }

  function filterPlans() {
    const term = state.searchTerms.plans;
    return state.plans.filter((plan) => {
      const assigned = Boolean(indexes.patientsByPlan.get(plan.id)?.length);
      const status = state.filters.plans.status;
      const statusMatch = status === "all" || (status === "assigned" ? assigned : !assigned);
      return statusMatch && matchesSearch([plan.title, plan.effective, plan.note], term);
    });
  }

  function filterDishes() {
    const term = state.searchTerms.dishes;
    const activeTags = Object.values(normalizeDishFilters(state.filters.dishes)).filter((value) => value && value !== "all");
    return state.dishes.filter((dishItem) => {
      const tags = dishItem.tags || [];
      const tagMatch = activeTags.every((tag) => tags.includes(tag));
      return tagMatch && matchesSearch([
        dishItem.title,
        tags.join(" "),
        (dishItem.ingredients || []).map((item) => item.item).join(" "),
        dishItem.preparation,
      ], term);
    });
  }

  function sortPatients(items) {
    return [...items].sort((a, b) => {
      if (state.sorts.patients === "label-asc") return a.label.localeCompare(b.label);
      if (state.sorts.patients === "status-asc") return patientStatusText(a).localeCompare(patientStatusText(b));
      return new Date(b.createdAt) - new Date(a.createdAt);
    });
  }

  function sortPlans(items) {
    return [...items].sort((a, b) => {
      if (state.sorts.plans === "title-asc") return a.title.localeCompare(b.title);
      if (state.sorts.plans === "assigned-desc") return (indexes.patientsByPlan.get(b.id)?.length || 0) - (indexes.patientsByPlan.get(a.id)?.length || 0);
      if (state.sorts.plans === "meals-desc") return allSlots(b).length - allSlots(a).length;
      if (state.sorts.plans === "patients-desc") return (indexes.patientsByPlan.get(b.id)?.length || 0) - (indexes.patientsByPlan.get(a.id)?.length || 0);
      return new Date(b.updatedAt || b.createdAt) - new Date(a.updatedAt || a.createdAt);
    });
  }

  function sortDishes(items) {
    return [...items].sort((a, b) => {
      if (state.sorts.dishes === "title-asc") return a.title.localeCompare(b.title);
      if (state.sorts.dishes === "used-desc") return (indexes.dishUsage.get(b.id) || 0) - (indexes.dishUsage.get(a.id) || 0);
      return new Date(b.updatedAt || b.createdAt) - new Date(a.updatedAt || a.createdAt);
    });
  }

  function paginated(list, items) {
    const size = state.pageSize[list] || pageSizeDefault;
    const maxPage = Math.max(1, Math.ceil(items.length / size));
    state.pages[list] = Math.min(Math.max(1, state.pages[list] || 1), maxPage);
    const start = (state.pages[list] - 1) * size;
    return { items: items.slice(start, start + size), maxPage };
  }

  function renderPagination(list, total) {
    const container = document.querySelector(`#${list === "plans" ? "plan" : list === "dishes" ? "dish" : "patient"}-pagination`);
    const size = state.pageSize[list] || pageSizeDefault;
    const maxPage = Math.max(1, Math.ceil(total / size));
    const page = Math.min(state.pages[list] || 1, maxPage);
    container.innerHTML = `
      <span class="page-range">${total ? `${(page - 1) * size + 1}-${Math.min(page * size, total)} of ${total}` : "0 results"}</span>
      <div class="pagination-actions">
        <button class="page-button" type="button" data-action="page-list" data-list="${list}" data-page="${page - 1}" ${page <= 1 ? "disabled" : ""} aria-label="Previous page">‹</button>
        <span class="page-index">${page} / ${maxPage}</span>
        <button class="page-button" type="button" data-action="page-list" data-list="${list}" data-page="${page + 1}" ${page >= maxPage ? "disabled" : ""} aria-label="Next page">›</button>
      </div>
    `;
  }

  function buildIndexes() {
    const patientsByPlan = new Map();
    const dishUsage = new Map();
    const latestCodeByPatient = new Map();
    state.patients.forEach((patient) => {
      if (!patient.activePlanId) return;
      const group = patientsByPlan.get(patient.activePlanId) || [];
      group.push(patient);
      patientsByPlan.set(patient.activePlanId, group);
    });
    state.plans.forEach((plan) => {
      new Set(allSlots(plan).map((slot) => slot.dishId).filter(Boolean)).forEach((dishId) => {
        dishUsage.set(dishId, (dishUsage.get(dishId) || 0) + 1);
      });
    });
    [...state.codes]
      .filter((code) => code.status === "active")
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .forEach((code) => {
        if (!latestCodeByPatient.has(code.patientId)) latestCodeByPatient.set(code.patientId, code);
      });
    return { patientsByPlan, dishUsage, latestCodeByPatient };
  }

  function groupSlots(slots) {
    const grouped = new Map(mealGroups.map((meal) => [meal, []]));
    grouped.set("Other", []);
    slots.forEach((slot) => {
      const match = mealGroups.find((meal) => String(slot.meal || "").toLowerCase().includes(meal.toLowerCase()));
      grouped.get(match || "Other").push(slot);
    });
    return grouped;
  }

  function patientMatchesStatus(patient, filter) {
    if (filter === "needs-plan") return !patient.activePlanId;
    if (filter === "planned") return Boolean(patient.activePlanId);
    if (filter === "pairing-active") {
      const code = latestCodeForPatient(patient.id);
      return Boolean(code && !isExpired(code));
    }
    if (filter === "paired") return patient.status === "paired";
    return true;
  }

  function setToolValues(list) {
    document.querySelectorAll(`[data-list="${list}"]`).forEach((control) => {
      const key = control.dataset.control;
      if (key === "sort") control.value = state.sorts[list];
      else if (key === "pageSize") control.value = String(state.pageSize[list]);
      else control.value = state.filters[list][key];
    });
  }

  function toolbarSearch(list, label, placeholder) {
    return `
      <label class="list-search">
        <span class="sr-only">${escapeHtml(label)}</span>
        <input type="search" data-list-search="${list}" value="${escapeAttribute(state.searchTerms[list] || "")}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}">
      </label>
    `;
  }

  function pageSizeSelect(list) {
    return `
      <label><span>Show</span>
        <select data-control="pageSize" data-list="${list}">
          <option value="25">25</option>
          <option value="50">50</option>
        </select>
      </label>
    `;
  }

  function dishFilterSelect(key, customTags = null) {
    const group = dishFilterGroups[key] || { label: "Other", allLabel: "All other tags", tags: customTags || [] };
    const tags = customTags || group.tags;
    const options = [`<option value="all">${escapeHtml(group.allLabel)}</option>`]
      .concat(tags.map((tag) => `<option value="${escapeAttribute(tag)}">${escapeHtml(titleCase(tag))}</option>`))
      .join("");
    return `
      <label><span>${escapeHtml(key === "meal" ? "Meal" : group.label)}</span>
        <select data-control="${escapeAttribute(key)}" data-list="dishes">
          ${options}
        </select>
      </label>
    `;
  }

  function otherDishTags() {
    const knownTags = new Set(Object.values(dishFilterGroups).flatMap((group) => group.tags));
    return [...new Set(state.dishes.flatMap((dish) => dish.tags || []))]
      .filter((tag) => !knownTags.has(tag))
      .sort();
  }

  function dishSummaryTags(dish) {
    return (dish.tags || []).slice(0, 4);
  }

  function dishStatTags(dish) {
    const tags = dish.tags || [];
    const preferred = [
      tags.find((tag) => dishFilterGroups.meal.tags.includes(tag)),
      tags.find((tag) => dishFilterGroups.nutrition.tags.includes(tag)),
      tags.find((tag) => dishFilterGroups.prep.tags.includes(tag)),
    ].filter(Boolean);
    return [...new Set(preferred.length ? preferred : tags.slice(0, 2))].slice(0, 3);
  }

  function dishFilterGroupForTag(tag) {
    return Object.entries(dishFilterGroups).find(([, group]) => group.tags.includes(tag))?.[0] || "other";
  }

  function normalizeDishFilters(value = {}) {
    const next = { ...defaultDishFilters() };
    Object.keys(next).forEach((key) => {
      if (typeof value[key] === "string") next[key] = value[key] || "all";
    });
    if (value.tag && value.tag !== "all") {
      next[dishFilterGroupForTag(value.tag)] = value.tag;
    }
    return next;
  }

  function titleCase(value) {
    return String(value || "").replace(/\b[a-z]/g, (letter) => letter.toUpperCase());
  }

  function photoOptions(selected) {
    return dishPhotos.map((photo) => `<option value="${photo.value}" ${photo.value === selected ? "selected" : ""}>${escapeHtml(photo.label)}</option>`).join("");
  }

  function tagChecks(selected = []) {
    return presetTags.map((tag) => `
      <label class="tag-check">
        <input type="checkbox" value="${escapeAttribute(tag)}" ${selected.includes(tag) ? "checked" : ""}>
        <span>${escapeHtml(tag)}</span>
      </label>
    `).join("");
  }

  function applySidebarState() {
    appPanel.classList.toggle("sidebar-collapsed", sidebarCollapsed);
    sidebarToggle.setAttribute("aria-pressed", String(sidebarCollapsed));
    sidebarToggle.setAttribute("aria-label", sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar");
    sidebarToggle.title = sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar";
    if (sidebarToggleLabel) sidebarToggleLabel.textContent = sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar";
  }

  function normalizeState(raw) {
    const fallback = {
      version: appStateVersion,
      demoDataVersion: "",
      dishes: [],
      plans: [],
      patients: [],
      codes: [],
      searchTerms: defaultSearchTerms(),
      filters: defaultFilters(),
      sorts: defaultSorts(),
      pages: defaultPages(),
      pageSize: defaultPageSizes(),
      lastUsedDishIds: [],
      lastUsedPlanIds: [],
    };
    const next = { ...fallback, ...raw };
    next.searchTerms = { ...defaultSearchTerms(), ...(next.searchTerms || {}) };
    next.filters = mergeDeep(defaultFilters(), next.filters || {});
    next.filters.dishes = normalizeDishFilters(next.filters.dishes || {});
    next.sorts = { ...defaultSorts(), ...(next.sorts || {}) };
    next.pages = { ...defaultPages(), ...(next.pages || {}) };
    next.pageSize = { ...defaultPageSizes(), ...(next.pageSize || {}) };
    next.lastUsedDishIds = Array.isArray(next.lastUsedDishIds) ? next.lastUsedDishIds : [];
    next.lastUsedPlanIds = Array.isArray(next.lastUsedPlanIds) ? next.lastUsedPlanIds : [];
    next.dishes = normalizeDishes(next.dishes);
    next.plans = normalizePlans(next.plans, next.dishes);
    next.patients = normalizePatients(next.patients);
    next.codes = normalizeCodes(next.codes);
    next.selectedPatientId = next.selectedPatientId || next.patients[0]?.id || null;
    next.selectedPlanId = next.selectedPlanId || next.plans[0]?.id || null;
    next.selectedDishId = next.selectedDishId || next.dishes[0]?.id || null;
    next.sidebarCollapsed = Boolean(next.sidebarCollapsed);
    return next;
  }

  function defaultSearchTerms() {
    return { patients: "", plans: "", dishes: "" };
  }

  function defaultFilters() {
    return {
      patients: { plan: "all", status: "all" },
      plans: { status: "all" },
      dishes: defaultDishFilters(),
    };
  }

  function defaultDishFilters() {
    return { meal: "all", nutrition: "all", prep: "all", cuisine: "all", other: "all" };
  }

  function defaultSorts() {
    return { patients: "created-desc", plans: "updated-desc", dishes: "updated-desc" };
  }

  function defaultPages() {
    return { patients: 1, plans: 1, dishes: 1 };
  }

  function defaultPageSizes() {
    return { patients: pageSizeDefault, plans: pageSizeDefault, dishes: pageSizeDefault };
  }

  function mergeDeep(base, extra) {
    return Object.fromEntries(Object.entries(base).map(([key, value]) => [key, { ...value, ...(extra[key] || {}) }]));
  }

  function seedIfEmpty() {
    const shouldUpgradeOldDemo = state.demoDataVersion !== richDemoDataVersion && state.plans.length <= 2 && state.patients.length <= 3;
    if (state.dishes.length && state.plans.length && state.patients.length && !shouldUpgradeOldDemo) return;
    const seeded = seedState();
    if (!state.dishes.length || shouldUpgradeOldDemo) state.dishes = seeded.dishes;
    if (!state.plans.length || shouldUpgradeOldDemo) state.plans = seeded.plans;
    if (!state.patients.length || shouldUpgradeOldDemo) state.patients = seeded.patients;
    state.demoDataVersion = richDemoDataVersion;
    selectedPatientId = state.patients.some((patient) => patient.id === state.selectedPatientId) ? state.selectedPatientId : state.patients[0]?.id || null;
    selectedPlanId = state.plans.some((plan) => plan.id === state.selectedPlanId) ? state.selectedPlanId : state.plans[0]?.id || null;
    selectedDishId = state.dishes.some((dishItem) => dishItem.id === state.selectedDishId) ? state.selectedDishId : state.dishes[0]?.id || null;
    persist({ quiet: true });
  }

  function seedState() {
    const richSeed = richDemoSeedState();
    if (richSeed) return richSeed;

    const chicken = dish("Chicken Salad Bowl", dishPhotos[0].value, ["high protein", "low carb", "lunch", "quick"], [
      ingredient("120", "g", "grilled chicken", "sliced"),
      ingredient("2", "cups", "leafy greens", ""),
      ingredient("1/2", "cup", "cucumber", "sliced"),
      ingredient("1/4", "", "avocado", ""),
    ], "Assemble greens, chicken, cucumber, tomato, and avocado. Finish with light vinaigrette.", "Use the portion approach reviewed with the patient.", ["Swap chicken for tofu or tuna."]);
    const yogurt = dish("Greek Yogurt Berry Bowl", dishPhotos[1].value, ["high protein", "breakfast", "quick"], [
      ingredient("1", "cup", "Greek yogurt", "plain"),
      ingredient("1/2", "cup", "berries", ""),
      ingredient("1", "tbsp", "chia seeds", ""),
      ingredient("1", "tbsp", "walnuts", "chopped"),
    ], "Add yogurt to a bowl and top with berries, chia seeds, and walnuts.", "Keep this repeatable for busy mornings.", ["Swap yogurt for cottage cheese."]);
    const salmon = dish("Salmon Vegetable Plate", dishPhotos[2].value, ["high protein", "dinner"], [
      ingredient("1", "fillet", "salmon", "roasted"),
      ingredient("2", "cups", "vegetables", "roasted"),
      ingredient("1", "small", "brown rice portion", ""),
    ], "Roast salmon and vegetables. Plate with a small rice portion and herbs.", "Stop when comfortably satisfied.", ["Swap salmon for beans, turkey, or eggs."]);
    const tofu = dish("Tofu Grain Bowl", dishPhotos[3].value, ["vegetarian", "high protein", "lunch"], [
      ingredient("120", "g", "tofu", "golden cubes"),
      ingredient("1/2", "cup", "quinoa", ""),
      ingredient("1/2", "cup", "edamame", ""),
      ingredient("1", "cup", "greens", ""),
    ], "Layer greens, quinoa, tofu, edamame, and vegetables. Finish with tahini dressing.", "Use as a vegetarian lunch or dinner base.", ["Swap tofu for tempeh or beans."]);
    const dishes = [chicken, yogurt, salmon, tofu];
    const balanced = samplePlan("balanced", dishes);
    const protein = samplePlan("protein", dishes);
    return {
      dishes,
      plans: [balanced, protein],
      patients: [
        { id: crypto.randomUUID(), label: "Patient 014", activePlanId: balanced.id, status: "paired", createdAt: daysAgo(5) },
        { id: crypto.randomUUID(), label: "Patient 027", activePlanId: protein.id, status: "ready", createdAt: daysAgo(2) },
      ],
    };
  }

  function richDemoSeedState() {
    const source = window.LeafstepProDemoData;
    if (!source?.dishes?.length || !source?.plans?.length) return null;
    const dishes = normalizeDishes(cloneSeedValue(source.dishes));
    const plans = normalizePlans(cloneSeedValue(source.plans), dishes);
    if (!dishes.length || !plans.length) return null;
    const steadyPlan = plans.find((plan) => plan.title === "Steady Week Support Plan") || plans[0];
    const proteinPlan = plans.find((plan) => plan.title === "High Protein Basics") || plans[1] || plans[0];
    return {
      dishes,
      plans,
      patients: [
        { id: crypto.randomUUID(), label: "Patient 014", activePlanId: steadyPlan.id, status: "paired", createdAt: daysAgo(5) },
        { id: crypto.randomUUID(), label: "Patient 027", activePlanId: proteinPlan.id, status: "ready", createdAt: daysAgo(2) },
      ],
    };
  }

  function cloneSeedValue(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function samplePlan(kind, dishes = state.dishes) {
    const isProtein = kind === "protein";
    const plan = {
      id: crypto.randomUUID(),
      title: isProtein ? "High Protein Basics" : "Steady Week Support Plan",
      effective: isProtein ? "Next 7 days" : "This week",
      note: isProtein ? "Protein-forward meals using saved dishes and simple swaps." : "Simple weekly guidance assembled from reusable dishes.",
      days: emptyWeek(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    const [chicken, yogurt, salmon, tofu] = dishes;
    addSeedSlot(plan, "Monday", "Breakfast", "8:00 AM", yogurt?.id, "Keep this one simple and repeatable.");
    addSeedSlot(plan, "Monday", "Lunch", "12:30 PM", chicken?.id, "Use the approved dressing portion.");
    addSeedSlot(plan, "Monday", "Dinner", "6:30 PM", isProtein ? chicken?.id : salmon?.id, "");
    addSeedSlot(plan, "Tuesday", "Lunch", "12:30 PM", isProtein ? chicken?.id : tofu?.id, "Pack ahead if the afternoon is busy.");
    return plan;
  }

  function addSeedSlot(plan, dayName, meal, time, dishId, note) {
    ensureDay(plan, dayName).slots.push({ id: crypto.randomUUID(), day: dayName, meal, time, dishId, note });
  }

  function normalizeDishes(value) {
    if (!Array.isArray(value)) return [];
    return value.map((dishItem) => ({
      id: dishItem.id || crypto.randomUUID(),
      title: dishItem.title || "Untitled dish",
      photo: dishItem.photo || dishPhotos[0].value,
      tags: uniqueTags(dishItem.tags || []),
      ingredients: Array.isArray(dishItem.ingredients) ? dishItem.ingredients.map((item) => ({
        amount: item.amount || "",
        unit: item.unit || "",
        item: item.item || item.name || "",
        note: item.note || "",
      })).filter((item) => item.item) : [],
      preparation: dishItem.preparation || "",
      portionGuidance: dishItem.portionGuidance || dishItem.portion || "",
      swaps: Array.isArray(dishItem.swaps) ? dishItem.swaps : linesFromText(dishItem.swaps || ""),
      notes: dishItem.notes || dishItem.note || "",
      createdAt: dishItem.createdAt || new Date().toISOString(),
      updatedAt: dishItem.updatedAt || dishItem.createdAt || new Date().toISOString(),
    }));
  }

  function normalizePlans(value, dishes) {
    if (!Array.isArray(value)) return [];
    return value.map((plan) => {
      const next = {
        id: plan.id || crypto.randomUUID(),
        title: plan.title || "Untitled meal plan",
        effective: plan.effective || "This week",
        note: plan.note || "",
        days: normalizeDays(plan.days),
        createdAt: plan.createdAt || new Date().toISOString(),
        updatedAt: plan.updatedAt || plan.createdAt || new Date().toISOString(),
      };
      if ((!plan.days || !hasSlots(next)) && Array.isArray(plan.meals)) next.days = migrateMealRows(plan.meals, dishes);
      return next;
    });
  }

  function normalizeDays(value) {
    const normalized = emptyWeek();
    if (!Array.isArray(value)) return normalized;
    value.forEach((day) => {
      const target = ensureDay({ days: normalized }, day.title || day.day || days[0]);
      target.slots = Array.isArray(day.slots) ? day.slots.map((slot) => ({
        id: slot.id || crypto.randomUUID(),
        day: slot.day || day.title || day.day || target.title,
        meal: slot.meal || slot.title || "Meal",
        time: slot.time || "",
        dishId: slot.dishId || "",
        note: slot.note || "",
      })) : [];
    });
    return normalized;
  }

  function migrateMealRows(meals, dishes) {
    const migrated = emptyWeek();
    meals.forEach((meal) => {
      const generatedDish = {
        id: crypto.randomUUID(),
        title: meal.items || meal.meal || "Meal guidance",
        photo: dishPhotos[0].value,
        tags: uniqueTags([String(meal.meal || "").toLowerCase()].filter(Boolean)),
        ingredients: [{ amount: "", unit: "", item: meal.items || "Nutritionist guidance", note: "" }],
        preparation: "",
        portionGuidance: meal.items || "",
        swaps: meal.swaps ? [meal.swaps] : [],
        notes: "",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      dishes.push(generatedDish);
      const day = ensureDay({ days: migrated }, meal.day || "Monday");
      day.slots.push({
        id: crypto.randomUUID(),
        day: day.title,
        meal: meal.meal || "Meal",
        time: meal.time || "",
        dishId: generatedDish.id,
        note: meal.swaps || "",
      });
    });
    return migrated;
  }

  function normalizePatients(value) {
    if (!Array.isArray(value)) return [];
    return value.map((patient) => ({
      id: patient.id || crypto.randomUUID(),
      label: patient.label || "Patient label",
      activePlanId: patient.activePlanId || patient.planId || "",
      status: patient.status || "ready",
      createdAt: patient.createdAt || new Date().toISOString(),
    }));
  }

  function normalizeCodes(value) {
    if (!Array.isArray(value)) return [];
    return value.map((code) => ({
      id: code.id || crypto.randomUUID(),
      patientId: code.patientId,
      planId: code.planId,
      token: code.token || shortToken(),
      status: code.status || (code.revokedAt ? "revoked" : "active"),
      createdAt: code.createdAt || new Date().toISOString(),
      expiresAt: code.expiresAt || new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      revokedAt: code.revokedAt || null,
    }));
  }

  function dish(title, photo, tags, ingredients, preparation, portionGuidance, swaps) {
    return {
      id: crypto.randomUUID(),
      title,
      photo,
      tags,
      ingredients,
      preparation,
      portionGuidance,
      swaps,
      notes: "",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
  }

  function ingredient(amount, unit, item, note) {
    return { amount, unit, item, note };
  }

  function emptyWeek() {
    return days.map((day) => ({ title: day, slots: [] }));
  }

  function ensureDay(plan, dayName) {
    let day = plan.days.find((item) => item.title === dayName || item.day === dayName);
    if (!day) {
      day = { title: dayName, slots: [] };
      plan.days.push(day);
    }
    if (!day.title) day.title = dayName;
    if (!Array.isArray(day.slots)) day.slots = [];
    return day;
  }

  function hasSlots(plan) {
    return plan.days.some((day) => day.slots?.length);
  }

  function allSlots(plan) {
    return (plan?.days || []).flatMap((day) => (day.slots || []).map((slot) => ({ ...slot, day: slot.day || day.title })));
  }

  function latestCodeForPatient(patientId) {
    return indexes.latestCodeByPatient?.get(patientId) || null;
  }

  function activePairingCodes() {
    return state.codes.filter((code) => code.status === "active" && !isExpired(code));
  }

  function revokeActiveCodesForPatient(patientId) {
    state.codes = state.codes.map((code) => code.patientId === patientId && code.status === "active" ? revokedCopy(code) : code);
  }

  function revokedCopy(code) {
    return { ...code, status: "revoked", revokedAt: code.revokedAt || new Date().toISOString() };
  }

  function patientStatusText(patient) {
    const code = latestCodeForPatient(patient.id);
    if (!patient.activePlanId) return "Needs plan";
    if (code && !isExpired(code)) return "Pairing link active";
    if (patient.status === "paired") return "Paired";
    return "Ready to share";
  }

  function codeStatus(code) {
    if (code.status === "revoked") return "Revoked";
    if (isExpired(code)) return "Expired";
    return "Active";
  }

  function requestConfirm({ title, body, actionLabel, onConfirm }) {
    confirmTitle.textContent = title;
    confirmBody.textContent = body;
    confirmApprove.textContent = actionLabel;
    confirmApprove.onclick = () => {
      confirmDialog.close();
      onConfirm();
    };
    confirmDialog.showModal();
  }

  function metricCard(label, value, caption, tone = "") {
    return `
      <article class="metric-card ${tone ? `tone-${tone}` : ""}">
        <span>${escapeHtml(label)}</span>
        <strong>${escapeHtml(value)}</strong>
        <p>${escapeHtml(caption)}</p>
      </article>
    `;
  }

  function emptyRow(title, body) {
    const row = document.createElement("article");
    row.className = "record-row";
    row.innerHTML = `
      <div>
        <div class="record-title">${escapeHtml(title)}</div>
        <p class="record-meta">${escapeHtml(body)}</p>
      </div>
    `;
    return row;
  }

  function detailEmpty(title, body) {
    return `
      <div class="detail-empty">
        <div>
          <h3>${escapeHtml(title)}</h3>
          <p>${escapeHtml(body)}</p>
        </div>
      </div>
    `;
  }

  function matchesSearch(values, term) {
    if (!term) return true;
    const normalizedTerm = String(term).toLowerCase();
    return values.some((item) => String(item).toLowerCase().includes(normalizedTerm));
  }

  function formatIngredient(ingredientItem) {
    return [ingredientItem.amount, ingredientItem.unit, ingredientItem.item, ingredientItem.note].filter(Boolean).join(" ");
  }

  function linesFromText(text) {
    return String(text || "").split("\n").map((line) => line.trim()).filter(Boolean);
  }

  function splitTags(text) {
    return String(text || "").split(",").map((tag) => tag.trim().toLowerCase()).filter(Boolean);
  }

  function uniqueTags(tags) {
    return [...new Set((tags || []).map((tag) => String(tag).trim().toLowerCase()).filter(Boolean))];
  }

  function rememberId(list, id) {
    return [id, ...(list || []).filter((item) => item !== id)].slice(0, 8);
  }

  function findPatient(id) {
    return state.patients.find((patient) => patient.id === id);
  }

  function findPlan(id) {
    return state.plans.find((plan) => plan.id === id);
  }

  function findDish(id) {
    return state.dishes.find((dishItem) => dishItem.id === id);
  }

  function findCode(id) {
    return state.codes.find((code) => code.id === id);
  }

  function isExpired(code) {
    return new Date(code.expiresAt).getTime() <= Date.now();
  }

  function pairingPayload(code) {
    return `leafstep://pair?token=${encodeURIComponent(code.token)}&env=sandbox`;
  }

  function qrPreviewMarkup(token) {
    const size = 13;
    let seed = [...token].reduce((total, char) => total + char.charCodeAt(0), 0);
    const cells = [];
    for (let row = 0; row < size; row += 1) {
      for (let col = 0; col < size; col += 1) {
        const finder = inFinder(row, col, 0, 0) || inFinder(row, col, 0, 9) || inFinder(row, col, 9, 0);
        seed = (seed * 1103515245 + 12345) % 2147483648;
        const on = finder || seed % 7 < 3;
        cells.push(`<span class="qr-cell ${on ? "on" : ""} ${finder ? "finder" : ""}"></span>`);
      }
    }
    return `<div class="qr-grid">${cells.join("")}</div>`;
  }

  function inFinder(row, col, startRow, startCol) {
    const localRow = row - startRow;
    const localCol = col - startCol;
    if (localRow < 0 || localCol < 0 || localRow > 3 || localCol > 3) return false;
    return localRow === 0 || localRow === 3 || localCol === 0 || localCol === 3 || (localRow === 2 && localCol === 2);
  }

  function shortToken() {
    return crypto.randomUUID().replaceAll("-", "").slice(0, 16).toUpperCase();
  }

  function loadState() {
    try {
      return JSON.parse(localStorage.getItem(storageKey) || "{}");
    } catch {
      window.setTimeout(() => showSaveStatus("Could not read saved workspace. Using a fresh demo.", "error"), 0);
      return {};
    }
  }

  function persist(options = {}) {
    state.version = appStateVersion;
    state.demoDataVersion = state.demoDataVersion || richDemoDataVersion;
    state.selectedPatientId = selectedPatientId;
    state.selectedPlanId = selectedPlanId;
    state.selectedDishId = selectedDishId;
    state.sidebarCollapsed = sidebarCollapsed;
    try {
      localStorage.setItem(storageKey, JSON.stringify(state));
      if (!options.quiet) showSaveStatus("Saved", "ok");
    } catch {
      showSaveStatus("Could not save workspace locally.", "error");
    }
  }

  function showSaveStatus(message, type = "ok") {
    saveStatus.textContent = message;
    saveStatus.dataset.status = type;
    if (message === "Saved") {
      window.clearTimeout(showSaveStatus.timer);
      showSaveStatus.timer = window.setTimeout(() => {
        saveStatus.textContent = "";
        saveStatus.dataset.status = "";
      }, 1800);
    }
  }

  function value(selector) {
    return document.querySelector(selector).value.trim();
  }

  function dateDesc(a, b) {
    return new Date(b.createdAt || b.updatedAt) - new Date(a.createdAt || a.updatedAt);
  }

  function daysAgo(count) {
    return new Date(Date.now() - count * 24 * 60 * 60 * 1000).toISOString();
  }

  function formatDate(value) {
    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(value));
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function escapeAttribute(value) {
    return escapeHtml(value).replaceAll("`", "&#096;");
  }
})();
