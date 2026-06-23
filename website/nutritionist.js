(() => {
  const storageKey = "leafstepNutritionistPrototype";
  const demoAccessCode = "leafstep-pro";
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  const presetTags = [
    "high protein",
    "low carb",
    "diabetes-friendly",
    "vegetarian",
    "quick",
    "breakfast",
    "lunch",
    "dinner",
    "snack",
  ];
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
  const planDialog = document.querySelector("#plan-dialog");
  const planForm = document.querySelector("#plan-form");
  const slotDialog = document.querySelector("#slot-dialog");
  const slotForm = document.querySelector("#slot-form");
  const dishDialog = document.querySelector("#dish-dialog");
  const dishForm = document.querySelector("#dish-form");
  const pairingDialog = document.querySelector("#pairing-dialog");
  const confirmDialog = document.querySelector("#confirm-dialog");
  const confirmTitle = document.querySelector("#confirm-dialog-title");
  const confirmBody = document.querySelector("#confirm-dialog-body");
  const confirmApprove = document.querySelector("#confirm-approve");
  const confirmCancel = document.querySelector("#confirm-cancel");

  let activeView = state.activeView || "overview";
  let selectedPatientId = state.selectedPatientId || state.patients[0]?.id || null;
  let selectedPlanId = state.selectedPlanId || state.plans[0]?.id || null;
  let selectedDishId = state.selectedDishId || state.dishes[0]?.id || null;
  let activeTagFilter = state.activeTagFilter || "all";
  let searchTerm = "";

  const viewMeta = {
    overview: {
      title: "Workspace",
      kicker: "Practice workspace",
      search: false,
      actions: ["patient", "plan", "dish"],
    },
    patients: {
      title: "Patients",
      kicker: "Patient planning",
      search: true,
      searchLabel: "Search patients",
      placeholder: "Search patients or assigned plans",
      actions: ["patient"],
    },
    "meal-plans": {
      title: "Meal plans",
      kicker: "Weekly board",
      search: true,
      searchLabel: "Search meal plans",
      placeholder: "Search meal plans",
      actions: ["plan", "dish"],
    },
    "dish-library": {
      title: "Dish library",
      kicker: "Reusable dishes",
      search: true,
      searchLabel: "Search dishes",
      placeholder: "Search dishes",
      actions: ["dish"],
    },
    privacy: {
      title: "Privacy boundary",
      kicker: "Supervised-care limits",
      search: false,
      actions: [],
    },
  };

  seedIfEmpty();
  bindEvents();
  render();
  setActiveView(activeView, { preserveSearch: true });

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
      window.scrollTo({ top: 0, left: 0 });
      render();
      setActiveView(activeView, { preserveSearch: true });
    });

    searchInput.addEventListener("input", () => {
      searchTerm = searchInput.value.trim().toLowerCase();
      render();
    });

    document.querySelectorAll("[data-view]").forEach((button) => {
      button.addEventListener("click", () => setActiveView(button.dataset.view));
    });

    document.querySelectorAll("[data-view-shortcut]").forEach((button) => {
      button.addEventListener("click", () => setActiveView(button.dataset.viewShortcut));
    });

    document.querySelectorAll("[data-open-plan]").forEach((button) => {
      button.addEventListener("click", () => openPlanEditor());
    });

    document.querySelectorAll("[data-open-dish]").forEach((button) => {
      button.addEventListener("click", () => openDishEditor());
    });

    document.querySelectorAll("[data-focus-patient]").forEach((button) => {
      button.addEventListener("click", () => {
        setActiveView("patients");
        document.querySelector("#patient-label").focus();
      });
    });

    document.querySelector("#seed-plan").addEventListener("click", () => {
      const plan = samplePlan("balanced");
      plan.title = `Weekly Plan ${state.plans.length + 1}`;
      state.plans.push(plan);
      selectedPlanId = plan.id;
      persist();
      render();
    });

    document.querySelector("#reset-demo").addEventListener("click", () => {
      const seeded = seedState();
      state.dishes = seeded.dishes;
      state.plans = seeded.plans;
      state.patients = seeded.patients;
      state.codes = [];
      selectedPatientId = state.patients[0]?.id || null;
      selectedPlanId = state.plans[0]?.id || null;
      selectedDishId = state.dishes[0]?.id || null;
      activeTagFilter = "all";
      persist();
      render();
    });

    document.querySelector("#patient-form").addEventListener("submit", (event) => {
      event.preventDefault();
      const label = value("#patient-label");
      if (!label) return;
      const patient = {
        id: crypto.randomUUID(),
        label,
        activePlanId: document.querySelector("#patient-plan").value,
        status: "ready",
        createdAt: new Date().toISOString(),
      };
      state.patients.push(patient);
      selectedPatientId = patient.id;
      event.currentTarget.reset();
      persist();
      render();
    });

    planForm.addEventListener("submit", (event) => {
      event.preventDefault();
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
      }
      selectedPlanId = next.id;
      persist();
      planDialog.close();
      render();
    });

    slotForm.addEventListener("submit", (event) => {
      event.preventDefault();
      const plan = findPlan(document.querySelector("#slot-plan-id").value);
      if (!plan) return;

      let dishId = document.querySelector("#slot-dish").value;
      if (dishId === "__new__") {
        const dish = dishFromInlineFields();
        if (!dish.title) return;
        state.dishes.push(dish);
        selectedDishId = dish.id;
        dishId = dish.id;
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
      persist();
      slotDialog.close();
      render();
    });

    dishForm.addEventListener("submit", (event) => {
      event.preventDefault();
      const id = document.querySelector("#dish-id").value;
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
      persist();
      dishDialog.close();
      render();
    });

    document.querySelector("#slot-dish").addEventListener("change", toggleInlineDishFields);
    document.querySelector("#add-ingredient-row").addEventListener("click", () => {
      document.querySelector("#ingredient-rows").append(createIngredientRow());
    });
    confirmCancel.addEventListener("click", () => confirmDialog.close());

    document.querySelectorAll("[data-close-plan]").forEach((button) => {
      button.addEventListener("click", () => planDialog.close());
    });
    document.querySelectorAll("[data-close-slot]").forEach((button) => {
      button.addEventListener("click", () => slotDialog.close());
    });
    document.querySelectorAll("[data-close-dish]").forEach((button) => {
      button.addEventListener("click", () => dishDialog.close());
    });
    document.querySelectorAll("[data-close-pairing]").forEach((button) => {
      button.addEventListener("click", () => pairingDialog.close());
    });

    document.addEventListener("click", handleActionClick);
    document.addEventListener("change", handleActionChange);
  }

  function handleActionClick(event) {
    const target = event.target.closest("[data-action]");
    if (!target) return;

    const { action, id } = target.dataset;
    if (action === "select-patient") {
      selectedPatientId = id;
    }
    if (action === "select-plan") {
      selectedPlanId = id;
    }
    if (action === "select-dish") {
      selectedDishId = id;
    }
    if (action === "filter-tag") {
      activeTagFilter = target.dataset.tag || "all";
    }
    if (action === "open-plan") {
      openPlanEditor(findPlan(id));
      return;
    }
    if (action === "open-dish") {
      openDishEditor(findDish(id));
      return;
    }
    if (action === "duplicate-plan") {
      duplicatePlan(id);
    }
    if (action === "duplicate-dish") {
      duplicateDish(id);
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
      if (patient?.activePlanId) {
        selectedPlanId = patient.activePlanId;
        setActiveView("meal-plans");
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

    persist();
    render();
    if (target.dataset.viewShortcut) {
      setActiveView(target.dataset.viewShortcut, { preserveSearch: true });
    }
  }

  function handleActionChange(event) {
    const target = event.target.closest("[data-action]");
    if (!target) return;

    if (target.dataset.action === "change-patient-plan") {
      const patient = findPatient(target.dataset.id);
      if (!patient) return;
      patient.activePlanId = target.value;
      patient.status = target.value ? "ready" : "unassigned";
      revokeActiveCodesForPatient(patient.id);
      persist();
      render();
    }
  }

  function render() {
    state.activeView = activeView;
    state.selectedPatientId = selectedPatientId;
    state.selectedPlanId = selectedPlanId;
    state.selectedDishId = selectedDishId;
    state.activeTagFilter = activeTagFilter;
    renderMetrics();
    renderOverview();
    renderPlanOptions();
    renderPatients();
    renderPatientDetail();
    renderPlans();
    renderPlanBoard();
    renderDishFilters();
    renderDishes();
    renderDishDetail();
    renderPhotoOptions();
    renderTagOptions();
  }

  function setActiveView(view, options = {}) {
    activeView = viewMeta[view] ? view : "overview";
    if (!options.preserveSearch) {
      searchTerm = "";
      searchInput.value = "";
    }

    document.querySelectorAll("[data-view]").forEach((button) => {
      const isActive = button.dataset.view === activeView;
      button.classList.toggle("active", isActive);
      button.setAttribute("aria-pressed", String(isActive));
    });
    document.querySelectorAll("[data-view-panel]").forEach((panel) => {
      const isActive = panel.dataset.viewPanel === activeView;
      panel.classList.toggle("active-view", isActive);
      panel.hidden = !isActive;
    });

    const meta = viewMeta[activeView];
    viewTitle.textContent = meta.title;
    viewKicker.textContent = meta.kicker;
    searchWrapper.classList.toggle("is-hidden", !meta.search);
    searchLabel.textContent = meta.searchLabel || "Search workspace";
    if (meta.placeholder) searchInput.placeholder = meta.placeholder;
    document.querySelector("#quick-patient-action").classList.toggle("is-hidden", !meta.actions.includes("patient"));
    document.querySelector("#quick-plan-action").classList.toggle("is-hidden", !meta.actions.includes("plan"));
    document.querySelector("#quick-dish-action").classList.toggle("is-hidden", !meta.actions.includes("dish"));

    persist();
    render();
    window.scrollTo({ top: 0, left: 0 });
  }

  function renderMetrics() {
    const activeCodes = activePairingCodes();
    const assignedPlans = state.patients.filter((patient) => patient.activePlanId).length;
    document.querySelector("#metric-grid").innerHTML = [
      metricCard("Patients", state.patients.length, `${assignedPlans} with an active plan`),
      metricCard("Meal plans", state.plans.length, "Reusable weekly guidance"),
      metricCard("Dishes", state.dishes.length, "Saved for future plans"),
      metricCard("Active pairings", activeCodes.length, "Patient app access links"),
    ].join("");
  }

  function renderOverview() {
    const patientList = document.querySelector("#overview-patient-list");
    const activityList = document.querySelector("#overview-activity-list");
    patientList.innerHTML = "";
    activityList.innerHTML = "";

    const recentPatients = [...state.patients].slice(0, 4);
    if (recentPatients.length === 0) {
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
          <button class="button subtle" type="button" data-action="select-patient" data-id="${patient.id}" data-view-shortcut="patients">Open</button>
        `;
        patientList.append(row);
      });
    }

    const recentCodes = [...state.codes]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 4);
    if (recentCodes.length === 0) {
      activityList.append(emptyRow("No pairing activity", "Generate a pairing link from a patient when they are ready."));
    } else {
      recentCodes.forEach((code) => {
        const patient = findPatient(code.patientId);
        const status = codeStatus(code);
        const row = document.createElement("article");
        row.className = "record-row";
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient?.label || "Removed patient")}</div>
            <p class="record-meta">${status} · Expires ${formatDate(code.expiresAt)}</p>
          </div>
          <button class="button subtle" type="button" data-action="view-code" data-id="${code.id}">View</button>
        `;
        activityList.append(row);
      });
    }
  }

  function renderPlanOptions() {
    const patientPlan = document.querySelector("#patient-plan");
    patientPlan.innerHTML = `<option value="">No active plan yet</option>`;
    state.plans.forEach((plan) => {
      const option = document.createElement("option");
      option.value = plan.id;
      option.textContent = plan.title;
      patientPlan.append(option);
    });
  }

  function renderPatients() {
    const list = document.querySelector("#patient-list");
    const patients = filteredPatients();
    document.querySelector("#patient-count").textContent = `${patients.length} shown`;
    list.innerHTML = "";
    if (patients.length === 0) {
      list.append(emptyRow("No matching patients", "Create a patient label such as Patient 014."));
      return;
    }

    patients.forEach((patient) => {
      const plan = findPlan(patient.activePlanId);
      const row = document.createElement("button");
      row.className = `record-row selectable ${patient.id === selectedPatientId ? "selected" : ""}`;
      row.type = "button";
      row.dataset.action = "select-patient";
      row.dataset.id = patient.id;
      row.innerHTML = `
        <div>
          <div class="record-title">${escapeHtml(patient.label)}</div>
          <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${patientStatusText(patient)}</p>
        </div>
        <span class="pill ${patient.activePlanId ? "blue" : ""}">${patient.activePlanId ? "Planned" : "Needs plan"}</span>
      `;
      list.append(row);
    });
  }

  function renderPatientDetail() {
    const panel = document.querySelector("#patient-detail");
    const patient = findPatient(selectedPatientId) || state.patients[0];
    if (!patient) {
      panel.innerHTML = detailEmpty("No patient selected", "Create a patient label to assign meal guidance.");
      return;
    }
    selectedPatientId = patient.id;
    const plan = findPlan(patient.activePlanId);
    const activeCode = latestCodeForPatient(patient.id);
    const codeStatusText = activeCode ? codeStatus(activeCode) : "No active link";
    const planOptions = [`<option value="">No active plan</option>`]
      .concat(state.plans.map((item) => `<option value="${item.id}" ${item.id === patient.activePlanId ? "selected" : ""}>${escapeHtml(item.title)}</option>`))
      .join("");

    panel.innerHTML = `
      <div class="plan-detail-head">
        <div>
          <h3>${escapeHtml(patient.label)}</h3>
          <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${codeStatusText}</p>
        </div>
        <span class="pill ${plan ? "blue" : "danger"}">${plan ? "Active" : "Needs plan"}</span>
      </div>
      <div class="detail-stack">
        <label>
          Active plan
          <select class="inline-select wide-select" data-action="change-patient-plan" data-id="${patient.id}">
            ${planOptions}
          </select>
        </label>
        <div class="patient-action-grid">
          <button class="button primary" type="button" data-action="build-patient-plan" data-id="${patient.id}">${plan ? "Build plan" : "Create plan"}</button>
          <button class="button subtle" type="button" data-action="generate-code" data-id="${patient.id}" ${patient.activePlanId ? "" : "disabled"}>Generate pairing link</button>
          ${activeCode ? `<button class="button subtle" type="button" data-action="view-code" data-id="${activeCode.id}">View link</button>` : ""}
          ${activeCode && codeStatus(activeCode) === "Active" ? `<button class="button danger" type="button" data-action="revoke-code" data-id="${activeCode.id}">Revoke</button>` : ""}
          <button class="button danger" type="button" data-action="delete-patient" data-id="${patient.id}">Delete patient</button>
        </div>
        <section class="plan-note">
          <strong>Patient labels only</strong>
          <p>Use internal labels like Patient 014. The prototype does not need names, emails, diagnosis, weight history, or app activity.</p>
        </section>
        ${plan ? patientPlanPreview(plan) : ""}
      </div>
    `;
  }

  function renderPlans() {
    const list = document.querySelector("#plan-list");
    const plans = filteredPlans();
    document.querySelector("#plan-count").textContent = `${plans.length} shown`;
    list.innerHTML = "";
    if (plans.length === 0) {
      list.append(emptyRow("No matching plans", "Create a weekly plan or clear search."));
      return;
    }

    plans.forEach((plan) => {
      const assignments = state.patients.filter((patient) => patient.activePlanId === plan.id).length;
      const slotCount = allSlots(plan).length;
      const row = document.createElement("button");
      row.className = `record-row selectable ${plan.id === selectedPlanId ? "selected" : ""}`;
      row.type = "button";
      row.dataset.action = "select-plan";
      row.dataset.id = plan.id;
      row.innerHTML = `
        <div>
          <div class="record-title">${escapeHtml(plan.title)}</div>
          <p class="record-meta">${escapeHtml(plan.effective)} · ${slotCount} meals · ${assignments} patients</p>
        </div>
        <span class="pill">${assignments ? "Assigned" : "Draft"}</span>
      `;
      list.append(row);
    });
  }

  function renderPlanBoard() {
    const panel = document.querySelector("#plan-board-panel");
    const plan = findPlan(selectedPlanId) || state.plans[0];
    if (!plan) {
      panel.innerHTML = detailEmpty("No plan selected", "Create a weekly meal plan to add dishes.");
      return;
    }
    selectedPlanId = plan.id;
    const assignedPatients = state.patients.filter((patient) => patient.activePlanId === plan.id);
    panel.innerHTML = `
      <div class="plan-detail-head">
        <div>
          <h3>${escapeHtml(plan.title)}</h3>
          <p class="record-meta">${escapeHtml(plan.effective)} · ${assignedPatients.length} patients · Last updated ${formatDate(plan.updatedAt || plan.createdAt)}</p>
        </div>
        <div class="record-actions">
          <button class="button subtle" type="button" data-action="open-plan" data-id="${plan.id}">Edit details</button>
          <button class="button subtle" type="button" data-action="duplicate-plan" data-id="${plan.id}">Duplicate</button>
          <button class="button danger" type="button" data-action="delete-plan" data-id="${plan.id}">Delete</button>
        </div>
      </div>
      <p class="plan-note">${escapeHtml(plan.note || "Add saved dishes to the weekly board, or create a dish inline while planning.")}</p>
      <div class="week-board">
        ${days.map((dayName) => weekDayColumn(plan, dayName)).join("")}
      </div>
    `;
  }

  function weekDayColumn(plan, dayName) {
    const day = ensureDay(plan, dayName);
    return `
      <section class="week-day">
        <div class="week-day-head">
          <h4>${escapeHtml(dayName)}</h4>
          <button class="button subtle" type="button" data-action="add-slot" data-id="${plan.id}" data-day="${dayName}">Add meal</button>
        </div>
        <div class="slot-list">
          ${day.slots.length ? day.slots.map((slot) => slotCard(plan.id, slot)).join("") : `<p class="empty-inline">No meals yet.</p>`}
        </div>
      </section>
    `;
  }

  function slotCard(planId, slot) {
    const dish = findDish(slot.dishId);
    return `
      <article class="slot-card">
        <div class="slot-card-head">
          <img src="${escapeAttribute(dish?.photo || dishPhotos[0].value)}" alt="">
          <div>
            <strong>${escapeHtml(slot.meal || "Meal")}</strong>
            <p>${escapeHtml(slot.time || "Anytime")}</p>
          </div>
        </div>
        <h5>${escapeHtml(dish?.title || "Saved dish")}</h5>
        <p>${escapeHtml(slot.note || dish?.portionGuidance || "Nutritionist-authored dish guidance.")}</p>
        <div class="mini-tags">${(dish?.tags || []).slice(0, 3).map((tag) => `<span>${escapeHtml(tag)}</span>`).join("")}</div>
        <div class="record-actions">
          <button class="button subtle" type="button" data-action="edit-slot" data-id="${slot.id}" data-plan-id="${planId}">Edit</button>
          <button class="button danger" type="button" data-action="delete-slot" data-id="${slot.id}" data-plan-id="${planId}">Remove</button>
        </div>
      </article>
    `;
  }

  function renderDishFilters() {
    const bar = document.querySelector("#dish-filter-bar");
    const usedTags = [...new Set(state.dishes.flatMap((dish) => dish.tags || []))].sort();
    const tags = ["all", ...presetTags.filter((tag) => usedTags.includes(tag)), ...usedTags.filter((tag) => !presetTags.includes(tag))];
    bar.innerHTML = tags.map((tag) => `
      <button class="filter-chip ${tag === activeTagFilter ? "active" : ""}" type="button" data-action="filter-tag" data-tag="${escapeAttribute(tag)}">${escapeHtml(tag === "all" ? "All" : tag)}</button>
    `).join("");
  }

  function renderDishes() {
    const list = document.querySelector("#dish-list");
    const dishes = filteredDishes();
    document.querySelector("#dish-count").textContent = `${dishes.length} shown`;
    list.innerHTML = "";
    if (dishes.length === 0) {
      list.append(emptyRow("No matching dishes", "Create a dish or clear the search/filter."));
      return;
    }

    dishes.forEach((dish) => {
      const card = document.createElement("button");
      card.className = `dish-card ${dish.id === selectedDishId ? "selected" : ""}`;
      card.type = "button";
      card.dataset.action = "select-dish";
      card.dataset.id = dish.id;
      card.innerHTML = `
        <img src="${escapeAttribute(dish.photo)}" alt="">
        <div>
          <strong>${escapeHtml(dish.title)}</strong>
          <p>${escapeHtml((dish.tags || []).slice(0, 3).join(" · ") || "No tags")}</p>
        </div>
      `;
      list.append(card);
    });
  }

  function renderDishDetail() {
    const panel = document.querySelector("#dish-detail");
    const dish = findDish(selectedDishId) || state.dishes[0];
    if (!dish) {
      panel.innerHTML = detailEmpty("No dish selected", "Create reusable dishes to build meal plans faster.");
      return;
    }
    selectedDishId = dish.id;
    const usedIn = state.plans.filter((plan) => allSlots(plan).some((slot) => slot.dishId === dish.id)).length;
    panel.innerHTML = `
      <div class="dish-detail-hero">
        <img src="${escapeAttribute(dish.photo)}" alt="">
        <div>
          <h3>${escapeHtml(dish.title)}</h3>
          <p class="record-meta">${usedIn} meal plans · Updated ${formatDate(dish.updatedAt || dish.createdAt)}</p>
        </div>
      </div>
      <div class="mini-tags">${(dish.tags || []).map((tag) => `<span>${escapeHtml(tag)}</span>`).join("")}</div>
      <section class="dish-detail-section">
        <h4>Ingredients</h4>
        <ul>${dish.ingredients.map((ingredient) => `<li>${escapeHtml(formatIngredient(ingredient))}</li>`).join("")}</ul>
      </section>
      <section class="dish-detail-section">
        <h4>Preparation</h4>
        <p>${escapeHtml(dish.preparation || "No preparation method added.")}</p>
      </section>
      <section class="dish-detail-section">
        <h4>Portions and swaps</h4>
        <p>${escapeHtml(dish.portionGuidance || "Use nutritionist-written portion guidance.")}</p>
        <p class="record-meta">${escapeHtml((dish.swaps || []).join(" · ") || "No swaps listed.")}</p>
      </section>
      <div class="record-actions">
        <button class="button subtle" type="button" data-action="open-dish" data-id="${dish.id}">Edit</button>
        <button class="button subtle" type="button" data-action="duplicate-dish" data-id="${dish.id}">Duplicate</button>
        <button class="button danger" type="button" data-action="delete-dish" data-id="${dish.id}">Delete</button>
      </div>
    `;
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
    fillSlotDishOptions(slot?.dishId || state.dishes[0]?.id || "");
    resetInlineDishFields();
    toggleInlineDishFields();
    slotDialog.showModal();
  }

  function openDishEditor(dish = null) {
    document.querySelector("#dish-dialog-title").textContent = dish ? "Edit dish" : "Create dish";
    document.querySelector("#dish-id").value = dish?.id || "";
    document.querySelector("#dish-title").value = dish?.title || "";
    document.querySelector("#dish-photo").value = dish?.photo || dishPhotos[0].value;
    document.querySelector("#dish-custom-tags").value = (dish?.tags || []).filter((tag) => !presetTags.includes(tag)).join(", ");
    document.querySelector("#dish-portion").value = dish?.portionGuidance || "";
    document.querySelector("#dish-preparation").value = dish?.preparation || "";
    document.querySelector("#dish-swaps").value = (dish?.swaps || []).join("\n");
    document.querySelector("#dish-notes").value = dish?.notes || "";
    renderTagOptions(dish?.tags || []);
    const rows = document.querySelector("#ingredient-rows");
    rows.innerHTML = "";
    const ingredients = dish?.ingredients?.length ? dish.ingredients : [{ amount: "", unit: "", item: "", note: "" }];
    ingredients.forEach((ingredient) => rows.append(createIngredientRow(ingredient)));
    dishDialog.showModal();
  }

  function renderPhotoOptions() {
    ["#dish-photo", "#inline-dish-photo"].forEach((selector) => {
      const select = document.querySelector(selector);
      if (!select || select.dataset.ready === "true") return;
      select.innerHTML = dishPhotos.map((photo) => `<option value="${photo.value}">${escapeHtml(photo.label)}</option>`).join("");
      select.dataset.ready = "true";
    });
  }

  function renderTagOptions(selected = []) {
    const container = document.querySelector("#dish-tag-options");
    if (!container) return;
    container.innerHTML = presetTags.map((tag) => `
      <label class="tag-check">
        <input type="checkbox" value="${escapeAttribute(tag)}" ${selected.includes(tag) ? "checked" : ""}>
        <span>${escapeHtml(tag)}</span>
      </label>
    `).join("");
  }

  function createIngredientRow(ingredient = {}) {
    const row = document.createElement("div");
    row.className = "ingredient-row";
    row.innerHTML = `
      <label>
        Amount
        <input name="amount" placeholder="1" value="${escapeAttribute(ingredient.amount || "")}">
      </label>
      <label>
        Unit
        <input name="unit" placeholder="cup" value="${escapeAttribute(ingredient.unit || "")}">
      </label>
      <label>
        Ingredient
        <input name="item" placeholder="greens" value="${escapeAttribute(ingredient.item || "")}" required>
      </label>
      <label>
        Note
        <input name="note" placeholder="chopped" value="${escapeAttribute(ingredient.note || "")}">
      </label>
      <button class="remove-meal" type="button" aria-label="Remove ingredient row">-</button>
    `;
    row.querySelector(".remove-meal").addEventListener("click", () => row.remove());
    return row;
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

  function dishFromInlineFields() {
    return {
      id: crypto.randomUUID(),
      title: value("#inline-dish-title"),
      photo: document.querySelector("#inline-dish-photo").value || dishPhotos[0].value,
      tags: uniqueTags(splitTags(value("#inline-dish-tags"))),
      ingredients: parseInlineIngredients(value("#inline-dish-ingredients")),
      preparation: value("#inline-dish-preparation"),
      portionGuidance: "",
      swaps: [],
      notes: "",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
  }

  function parseInlineIngredients(text) {
    return text.split("\n").map((line) => {
      const parts = line.split("|").map((part) => part.trim());
      if (parts.length >= 3) {
        return { amount: parts[0], unit: parts[1], item: parts[2], note: parts[3] || "" };
      }
      return { amount: "", unit: "", item: line.trim(), note: "" };
    }).filter((ingredient) => ingredient.item);
  }

  function fillDayOptions(selector, selectedDay) {
    const select = document.querySelector(selector);
    select.innerHTML = days.map((dayName) => `<option value="${dayName}" ${dayName === selectedDay ? "selected" : ""}>${dayName}</option>`).join("");
  }

  function fillSlotDishOptions(selectedDish) {
    const select = document.querySelector("#slot-dish");
    select.innerHTML = state.dishes.map((dish) => `<option value="${dish.id}" ${dish.id === selectedDish ? "selected" : ""}>${escapeHtml(dish.title)}</option>`).join("");
    select.insertAdjacentHTML("beforeend", `<option value="__new__">Create new dish...</option>`);
  }

  function resetInlineDishFields() {
    document.querySelector("#inline-dish-title").value = "";
    document.querySelector("#inline-dish-tags").value = "";
    document.querySelector("#inline-dish-ingredients").value = "";
    document.querySelector("#inline-dish-preparation").value = "";
    document.querySelector("#inline-dish-photo").value = dishPhotos[0].value;
  }

  function toggleInlineDishFields() {
    document.querySelector("#inline-dish-fields").classList.toggle("hidden", document.querySelector("#slot-dish").value !== "__new__");
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
        render();
      },
    });
  }

  function confirmDeleteDish(id) {
    const useCount = state.plans.reduce((total, plan) => total + allSlots(plan).filter((slot) => slot.dishId === id).length, 0);
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

  function patientPlanPreview(plan) {
    const slots = allSlots(plan).slice(0, 5);
    return `
      <section class="dish-detail-section">
        <h4>Active plan preview</h4>
        ${slots.length ? slots.map((slot) => {
          const dish = findDish(slot.dishId);
          return `<p class="record-meta">${escapeHtml(slot.day)} · ${escapeHtml(slot.meal)} · ${escapeHtml(dish?.title || "Dish")}</p>`;
        }).join("") : `<p class="record-meta">No meals added yet.</p>`}
      </section>
    `;
  }

  function normalizeState(raw) {
    const fallback = { version: 2, dishes: [], plans: [], patients: [], codes: [] };
    const next = { ...fallback, ...raw };
    next.dishes = normalizeDishes(next.dishes);
    next.plans = normalizePlans(next.plans, next.dishes);
    next.patients = normalizePatients(next.patients);
    next.codes = normalizeCodes(next.codes);
    next.selectedPatientId = next.selectedPatientId || next.patients[0]?.id || null;
    next.selectedPlanId = next.selectedPlanId || next.plans[0]?.id || null;
    next.selectedDishId = next.selectedDishId || next.dishes[0]?.id || null;
    return next;
  }

  function seedIfEmpty() {
    if (state.dishes.length && state.plans.length && state.patients.length) return;
    const seeded = seedState();
    if (!state.dishes.length) state.dishes = seeded.dishes;
    if (!state.plans.length) state.plans = seeded.plans;
    if (!state.patients.length) state.patients = seeded.patients;
    selectedPatientId = state.selectedPatientId || state.patients[0]?.id || null;
    selectedPlanId = state.selectedPlanId || state.plans[0]?.id || null;
    selectedDishId = state.selectedDishId || state.dishes[0]?.id || null;
    persist();
  }

  function seedState() {
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
      if ((!plan.days || !hasSlots(next)) && Array.isArray(plan.meals)) {
        next.days = migrateMealRows(plan.meals, dishes);
      }
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

  function filteredPatients() {
    return state.patients.filter((patient) => matchesSearch([patient.label, findPlan(patient.activePlanId)?.title || "", patientStatusText(patient)]));
  }

  function filteredPlans() {
    return state.plans.filter((plan) => matchesSearch([plan.title, plan.effective, plan.note]));
  }

  function filteredDishes() {
    return state.dishes.filter((dishItem) => {
      const tagMatch = activeTagFilter === "all" || (dishItem.tags || []).includes(activeTagFilter);
      return tagMatch && matchesSearch([
        dishItem.title,
        (dishItem.tags || []).join(" "),
        (dishItem.ingredients || []).map((item) => item.item).join(" "),
        dishItem.preparation,
      ]);
    });
  }

  function matchesSearch(values) {
    if (!searchTerm) return true;
    return values.some((item) => String(item).toLowerCase().includes(searchTerm));
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
    return [...state.codes]
      .filter((code) => code.patientId === patientId && code.status === "active")
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))[0] || null;
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

  function metricCard(label, value, caption) {
    return `
      <article class="metric-card">
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
      return {};
    }
  }

  function persist() {
    state.version = 2;
    state.activeView = activeView;
    state.selectedPatientId = selectedPatientId;
    state.selectedPlanId = selectedPlanId;
    state.selectedDishId = selectedDishId;
    state.activeTagFilter = activeTagFilter;
    localStorage.setItem(storageKey, JSON.stringify(state));
  }

  function value(selector) {
    return document.querySelector(selector).value.trim();
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
