(() => {
  const storageKey = "leafstepNutritionistPrototype";
  const demoAccessCode = "leafstep-pro";
  const state = normalizeState(loadState());

  const loginPanel = document.querySelector("#login-panel");
  const appPanel = document.querySelector("#app-panel");
  const loginForm = document.querySelector("#login-form");
  const loginError = document.querySelector("#login-error");
  const accessCode = document.querySelector("#access-code");
  const planDialog = document.querySelector("#plan-dialog");
  const pairingDialog = document.querySelector("#pairing-dialog");
  const confirmDialog = document.querySelector("#confirm-dialog");
  const planForm = document.querySelector("#plan-form");
  const confirmTitle = document.querySelector("#confirm-dialog-title");
  const confirmBody = document.querySelector("#confirm-dialog-body");
  const confirmApprove = document.querySelector("#confirm-approve");
  const confirmCancel = document.querySelector("#confirm-cancel");
  const patientForm = document.querySelector("#patient-form");
  const planList = document.querySelector("#plan-list");
  const planDetail = document.querySelector("#plan-detail");
  const patientList = document.querySelector("#patient-list");
  const codeList = document.querySelector("#code-list");
  const patientPlan = document.querySelector("#patient-plan");
  const searchInput = document.querySelector("#workspace-search");
  const searchWrapper = document.querySelector("#search-wrapper");
  const searchLabel = document.querySelector("#search-label");
  const viewTitle = document.querySelector("#view-title");
  const viewKicker = document.querySelector("#view-kicker");
  const mealRows = document.querySelector("#meal-rows");
  const pairingDialogBody = document.querySelector("#pairing-dialog-body");

  let selectedPlanId = state.selectedPlanId || state.plans[0]?.id || null;
  let activePairingCodeId = null;
  let activeView = state.activeView || "overview";
  let searchTerm = "";

  const viewMeta = {
    overview: {
      title: "Workspace",
      kicker: "Practice workspace",
      search: false,
      actions: ["plan", "slot"],
    },
    "meal-plans": {
      title: "Meal plans",
      kicker: "Reusable guidance",
      search: true,
      searchLabel: "Search meal plans",
      placeholder: "Search meal plans",
      actions: ["plan"],
    },
    "patient-slots": {
      title: "Client access",
      kicker: "Pseudonymous access",
      search: true,
      searchLabel: "Search access slots",
      placeholder: "Search access slots",
      actions: ["slot"],
    },
    "pairing-codes": {
      title: "Pairing access",
      kicker: "Access history",
      search: true,
      searchLabel: "Search pairing links",
      placeholder: "Search pairing links",
      actions: [],
    },
    privacy: {
      title: "Privacy boundary",
      kicker: "Supervised-care limits",
      search: false,
      actions: [],
    },
  };

  if (state.plans.length === 0) {
    state.plans.push(samplePlan("steady"));
    state.plans.push(samplePlan("protein"));
    selectedPlanId = state.plans[0].id;
    persist();
  }

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

  document.querySelector("#seed-plan").addEventListener("click", () => {
    const plan = samplePlan(state.plans.length % 2 === 0 ? "steady" : "protein");
    plan.title = `${plan.title} ${state.plans.length + 1}`;
    state.plans.push(plan);
    selectedPlanId = plan.id;
    persist();
    render();
  });

  document.querySelector("#reset-demo").addEventListener("click", () => {
    const steady = samplePlan("steady");
    const protein = samplePlan("protein");
    state.plans = [steady, protein];
    state.patients = [
      {
        id: crypto.randomUUID(),
        label: "Client 014",
        planId: steady.id,
        status: "paired",
        createdAt: daysAgo(5),
      },
      {
        id: crypto.randomUUID(),
        label: "Practice ID 7",
        planId: protein.id,
        status: "ready",
        createdAt: daysAgo(2),
      },
    ];
    state.codes = [];
    selectedPlanId = steady.id;
    activePairingCodeId = null;
    persist();
    render();
  });

  document.querySelectorAll("[data-open-plan]").forEach((button) => {
    button.addEventListener("click", () => openPlanEditor());
  });

  document.querySelector("[data-focus-slot]").addEventListener("click", () => {
    setActiveView("patient-slots");
    document.querySelector("#patient-label").focus();
  });

  document.querySelectorAll("[data-close-dialog]").forEach((button) => {
    button.addEventListener("click", () => planDialog.close());
  });

  document.querySelectorAll("[data-close-pairing]").forEach((button) => {
    button.addEventListener("click", () => pairingDialog.close());
  });

  document.querySelector("#add-meal-row").addEventListener("click", () => {
    mealRows.append(createMealRow());
  });

  document.querySelectorAll("[data-view]").forEach((button) => {
    button.addEventListener("click", () => {
      setActiveView(button.dataset.view);
    });
  });

  document.querySelectorAll("[data-view-shortcut]").forEach((button) => {
    button.addEventListener("click", () => {
      setActiveView(button.dataset.viewShortcut);
    });
  });

  planForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const planId = document.querySelector("#plan-id").value;
    const plan = {
      id: planId || crypto.randomUUID(),
      title: value("#plan-title"),
      effective: value("#plan-effective"),
      note: value("#plan-note"),
      meals: readMealRows(),
      updatedAt: new Date().toISOString(),
      createdAt: planId ? findPlan(planId)?.createdAt || new Date().toISOString() : new Date().toISOString(),
    };

    if (planId) {
      state.plans = state.plans.map((item) => item.id === planId ? plan : item);
    } else {
      state.plans.push(plan);
    }

    selectedPlanId = plan.id;
    persist();
    planDialog.close();
    render();
  });

  patientForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const planId = patientPlan.value;
    if (!planId) return;

    state.patients.push({
      id: crypto.randomUUID(),
      label: value("#patient-label"),
      planId,
      status: "ready",
      createdAt: new Date().toISOString(),
    });
    persist();
    patientForm.reset();
    render();
  });

  document.addEventListener("click", async (event) => {
    const target = event.target.closest("[data-action]");
    if (!target) return;

    const action = target.dataset.action;
    const id = target.dataset.id;

    if (action === "select-plan") {
      selectedPlanId = id;
    }

    if (action === "edit-plan") {
      openPlanEditor(findPlan(id));
      return;
    }

    if (action === "duplicate-plan") {
      const source = findPlan(id);
      if (!source) return;
      const copy = {
        ...source,
        id: crypto.randomUUID(),
        title: `${source.title} copy`,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      state.plans.push(copy);
      selectedPlanId = copy.id;
    }

    if (action === "delete-plan") {
      requestConfirm({
        title: "Delete this meal plan?",
        body: "This removes the reusable plan and clears it from assigned access slots. Active pairing links for this plan will be revoked.",
        actionLabel: "Delete plan",
        onConfirm: () => {
          state.plans = state.plans.filter((plan) => plan.id !== id);
          state.patients = state.patients.map((patient) => patient.planId === id ? { ...patient, planId: "" } : patient);
          state.codes = state.codes.map((code) => code.planId === id ? { ...code, status: "revoked", revokedAt: new Date().toISOString() } : code);
          selectedPlanId = state.plans[0]?.id || null;
          persist();
          render();
        },
      });
      return;
    }

    if (action === "assign-plan") {
      const patient = findPatient(id);
      if (!patient) return;
      const nextPlan = nextPlanId(patient.planId);
      patient.planId = nextPlan;
      patient.status = nextPlan ? "ready" : "unassigned";
    }

    if (action === "delete-patient") {
      requestConfirm({
        title: "Remove this access slot?",
        body: "This removes the internal access slot and revokes any active pairing link for it. No app progress data is affected.",
        actionLabel: "Remove slot",
        onConfirm: () => {
          state.patients = state.patients.filter((patient) => patient.id !== id);
          state.codes = state.codes.map((code) => code.patientId === id ? { ...code, status: "revoked", revokedAt: new Date().toISOString() } : code);
          persist();
          render();
        },
      });
      return;
    }

    if (action === "generate-code") {
      const patient = findPatient(id);
      if (!patient || !patient.planId) return;
      const code = {
        id: crypto.randomUUID(),
        patientId: patient.id,
        planId: patient.planId,
        token: shortToken(),
        status: "active",
        createdAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
        revokedAt: null,
      };
      state.codes.push(code);
      patient.status = "invited";
      activePairingCodeId = code.id;
      persist();
      render();
      openPairingDialog(code.id);
      return;
    }

    if (action === "view-code") {
      openPairingDialog(id);
      return;
    }

    if (action === "revoke-code") {
      requestConfirm({
        title: "Revoke this pairing link?",
        body: "This stops the one-time pairing link from being used. You can generate a new link later if needed.",
        actionLabel: "Revoke link",
        onConfirm: () => {
          revokeCode(id);
          persist();
          render();
        },
      });
      return;
    }

    if (action === "copy-code") {
      const code = findCode(id);
      if (code) {
        await navigator.clipboard.writeText(pairingPayload(code));
        target.textContent = "Copied";
        window.setTimeout(() => {
          target.textContent = "Copy secure pairing link";
        }, 1400);
      }
    }

    persist();
    render();
    if (target.dataset.viewShortcut) {
      setActiveView(target.dataset.viewShortcut, { preserveSearch: true });
    }
  });

  document.addEventListener("change", (event) => {
    const target = event.target.closest("[data-action]");
    if (!target) return;

    if (target.dataset.action === "change-patient-plan") {
      const patient = findPatient(target.dataset.id);
      if (!patient) return;
      patient.planId = target.value;
      patient.status = target.value ? "ready" : "unassigned";
      state.codes = state.codes.map((code) => code.patientId === patient.id && code.status === "active"
        ? { ...code, status: "revoked", revokedAt: new Date().toISOString() }
        : code);
      persist();
      render();
    }
  });

  confirmCancel.addEventListener("click", () => {
    confirmDialog.close();
  });

  render();
  setActiveView(activeView, { preserveSearch: true });

  function render() {
    state.selectedPlanId = selectedPlanId;
    state.activeView = activeView;
    renderMetrics();
    renderOverview();
    renderPlans();
    renderPlanDetail();
    renderPatientPlanOptions();
    renderPatients();
    renderCodes();
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

    viewTitle.textContent = viewMeta[activeView].title;
    viewKicker.textContent = viewMeta[activeView].kicker;
    searchWrapper.classList.toggle("is-hidden", !viewMeta[activeView].search);
    searchLabel.textContent = viewMeta[activeView].searchLabel || "Search workspace";
    document.querySelector("#quick-plan-action").classList.toggle("is-hidden", !viewMeta[activeView].actions.includes("plan"));
    document.querySelector("#quick-slot-action").classList.toggle("is-hidden", !viewMeta[activeView].actions.includes("slot"));
    if (viewMeta[activeView].placeholder) {
      searchInput.placeholder = viewMeta[activeView].placeholder;
    }

    state.activeView = activeView;
    persist();
    render();
    window.scrollTo({ top: 0, left: 0 });
  }

  function renderMetrics() {
    const activeCodes = activePairingCodes();
    const revokedCodes = state.codes.filter((code) => code.status === "revoked").length;
    const readySlots = state.patients.filter((patient) => patient.planId && !state.codes.some((code) => code.patientId === patient.id && code.status === "active" && !isExpired(code))).length;
    document.querySelector("#metric-grid").innerHTML = [
      metricCard("Reusable plans", state.plans.length, "Ready to assign to slots"),
      metricCard("Slots ready", readySlots, "Assigned plans without active pairing link"),
      metricCard("Active links", activeCodes.length, "Short-lived pairing access"),
      metricCard("Revoked/expired", revokedCodes + expiredCodes().length, "Access can be stopped anytime"),
    ].join("");
  }

  function renderOverview() {
    const planList = document.querySelector("#overview-plan-list");
    const activityList = document.querySelector("#overview-activity-list");
    const recentPlans = [...state.plans]
      .sort((a, b) => new Date(b.updatedAt || b.createdAt) - new Date(a.updatedAt || a.createdAt))
      .slice(0, 3);
    const recentCodes = [...state.codes]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 3);

    planList.innerHTML = "";
    if (recentPlans.length === 0) {
      planList.append(emptyRow("No plans yet", "Create a meal plan to start the supervised-care flow."));
    } else {
      recentPlans.forEach((plan) => {
        const assignments = state.patients.filter((patient) => patient.planId === plan.id).length;
        const row = document.createElement("article");
        row.className = "record-row";
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(plan.title)}</div>
            <p class="record-meta">${escapeHtml(plan.effective)} · ${assignments} assigned slots</p>
          </div>
          <button class="button subtle" type="button" data-action="select-plan" data-id="${plan.id}" data-view-shortcut="meal-plans">Open</button>
        `;
        planList.append(row);
      });
    }

    activityList.innerHTML = "";
    if (recentCodes.length === 0) {
      activityList.append(emptyRow("No pairing activity", "Generate access from a patient slot when the patient is ready to pair."));
    } else {
      recentCodes.forEach((code) => {
        const patient = findPatient(code.patientId);
        const status = code.status === "revoked" ? "Revoked" : isExpired(code) ? "Expired" : "Active";
        const row = document.createElement("article");
        row.className = "record-row";
        row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient?.label || "Removed slot")}</div>
            <p class="record-meta">${status} · Expires ${formatDate(code.expiresAt)}</p>
          </div>
          <button class="button subtle" type="button" data-action="view-code" data-id="${code.id}">View</button>
        `;
        activityList.append(row);
      });
    }
  }

  function renderPlans() {
    const plans = filteredPlans();
    document.querySelector("#plan-count").textContent = `${plans.length} shown`;
    planList.innerHTML = "";

    if (plans.length === 0) {
      planList.append(emptyRow("No matching plans", "Create a reusable plan or clear the search field."));
      return;
    }

    plans.forEach((plan) => {
      const assignments = state.patients.filter((patient) => patient.planId === plan.id).length;
      const row = document.createElement("button");
      row.className = `record-row selectable ${plan.id === selectedPlanId ? "selected" : ""}`;
      row.type = "button";
      row.dataset.action = "select-plan";
      row.dataset.id = plan.id;
      row.innerHTML = `
        <div>
          <div class="record-title">${escapeHtml(plan.title)}</div>
          <p class="record-meta">${escapeHtml(plan.effective)} · ${countMeals(plan.meals)} meals · ${assignments} slots</p>
        </div>
        <span class="pill">${assignments ? "Assigned" : "Draft"}</span>
      `;
      planList.append(row);
    });
  }

  function renderPlanDetail() {
    const plan = findPlan(selectedPlanId) || state.plans[0];
    if (!plan) {
      planDetail.innerHTML = `
        <div class="detail-empty">
          <div>
            <h3>No plan selected</h3>
            <p>Create a meal plan to preview what the patient will read in the app.</p>
          </div>
        </div>
      `;
      return;
    }

    const grouped = groupMealsByDay(plan.meals);
    planDetail.innerHTML = `
      <div class="plan-detail-head">
        <div>
          <h3>${escapeHtml(plan.title)}</h3>
          <p class="record-meta">${escapeHtml(plan.effective)} · Last updated ${formatDate(plan.updatedAt || plan.createdAt)}</p>
        </div>
        <span class="pill blue">Read-only in app</span>
      </div>
      <p class="plan-note">${escapeHtml(plan.note || "Nutritionist-written guidance appears read-only in the app.")}</p>
      <div class="record-actions">
        <button class="button subtle" type="button" data-action="edit-plan" data-id="${plan.id}">Edit</button>
        <button class="button subtle" type="button" data-action="duplicate-plan" data-id="${plan.id}">Duplicate</button>
        <button class="button danger" type="button" data-action="delete-plan" data-id="${plan.id}">Delete</button>
      </div>
      <div class="day-list">
        ${grouped.map((group) => `
          <section class="day-group">
            <h4>${escapeHtml(group.day)}</h4>
            ${group.items.map((meal) => `
              <article class="meal-item">
                <div class="meal-time">${escapeHtml(meal.time || "Anytime")}</div>
                <div>
                  <strong>${escapeHtml(meal.meal || "Meal")}</strong>
                  <p>${escapeHtml(meal.items || "Nutritionist-written guidance.")}</p>
                  <p class="record-meta">${escapeHtml(meal.swaps || "No swaps listed.")}</p>
                </div>
              </article>
            `).join("")}
          </section>
        `).join("")}
      </div>
    `;
  }

  function renderPatientPlanOptions() {
    patientPlan.innerHTML = "";
    if (state.plans.length === 0) {
      const option = document.createElement("option");
      option.value = "";
      option.textContent = "Create a plan first";
      patientPlan.append(option);
      return;
    }

    state.plans.forEach((plan) => {
      const option = document.createElement("option");
      option.value = plan.id;
      option.textContent = plan.title;
      patientPlan.append(option);
    });
  }

  function renderPatients() {
    const patients = filteredPatients();
    document.querySelector("#patient-count").textContent = `${patients.length} shown`;
    patientList.innerHTML = "";

    if (patients.length === 0) {
      patientList.append(emptyRow("No matching patient slots", "Create a pseudonymous slot and assign one plan."));
      return;
    }

    patients.forEach((patient) => {
      const plan = findPlan(patient.planId);
      const latestCode = state.codes.find((code) => code.patientId === patient.id && code.status === "active");
      const planOptions = state.plans.map((item) => `
        <option value="${item.id}" ${item.id === patient.planId ? "selected" : ""}>${escapeHtml(item.title)}</option>
      `).join("");
      const row = document.createElement("article");
      row.className = "record-row";
      row.innerHTML = `
          <div>
            <div class="record-title">${escapeHtml(patient.label)}</div>
            <p class="record-meta">${escapeHtml(plan?.title || "No active plan")} · ${statusLabel(patient, latestCode)}</p>
        </div>
        <div class="record-actions">
          <select class="inline-select" data-action="change-patient-plan" data-id="${patient.id}" aria-label="Change plan for ${escapeAttribute(patient.label)}">
            ${planOptions}
          </select>
          <button class="button primary" type="button" data-action="generate-code" data-id="${patient.id}" ${patient.planId ? "" : "disabled"}>Generate access</button>
          <button class="button danger" type="button" data-action="delete-patient" data-id="${patient.id}">Delete</button>
        </div>
      `;
      patientList.append(row);
    });
  }

  function renderCodes() {
    const codes = filteredCodes();
    document.querySelector("#code-count").textContent = `${codes.length} shown`;
    codeList.innerHTML = "";

    if (codes.length === 0) {
      codeList.append(emptyRow("No pairing activity", "Generate a pairing link from an access slot when the patient is ready."));
      return;
    }

    codes.forEach((code) => {
      const patient = findPatient(code.patientId);
      const plan = findPlan(code.planId);
      const expired = isExpired(code);
      const status = code.status === "revoked" ? "Revoked" : expired ? "Expired" : "Active";
      const row = document.createElement("article");
      row.className = "record-row";
      row.innerHTML = `
        <div>
          <div class="record-title">${escapeHtml(patient?.label || "Removed slot")}</div>
          <p class="record-meta">${escapeHtml(plan?.title || "Removed plan")} · ${status} · Expires ${formatDate(code.expiresAt)}</p>
        </div>
        <div class="record-actions">
          <span class="pill ${status === "Active" ? "lavender" : "danger"}">${status}</span>
          <button class="button subtle" type="button" data-action="view-code" data-id="${code.id}">View</button>
          <button class="button danger" type="button" data-action="revoke-code" data-id="${code.id}" ${status === "Active" ? "" : "disabled"}>Revoke</button>
        </div>
      `;
      codeList.append(row);
    });
  }

  function openPlanEditor(plan = null) {
    document.querySelector("#plan-dialog-title").textContent = plan ? "Edit plan" : "Create plan";
    document.querySelector("#plan-id").value = plan?.id || "";
    document.querySelector("#plan-title").value = plan?.title || "";
    document.querySelector("#plan-effective").value = plan?.effective || "";
    document.querySelector("#plan-note").value = plan?.note || "";
    mealRows.innerHTML = "";
    const meals = plan?.meals?.length ? plan.meals : defaultMealRows();
    meals.forEach((meal) => mealRows.append(createMealRow(meal)));
    planDialog.showModal();
  }

  function openPairingDialog(codeId) {
    const code = findCode(codeId);
    if (!code) return;
    const patient = findPatient(code.patientId);
    const plan = findPlan(code.planId);
    const payload = pairingPayload(code);
    pairingDialogBody.innerHTML = `
      <div class="pairing-card">
        <div class="qr-preview" aria-hidden="true">${qrPreviewMarkup(code.token)}</div>
        <div>
          <p class="record-meta">Secure · one-time · expires ${formatDate(code.expiresAt)}</p>
          <h3>${escapeHtml(patient?.label || "Removed slot")}</h3>
          <p>${escapeHtml(plan?.title || "Assigned meal plan")}</p>
          <p>This grants read-only meal plan access. Leafstep does not receive progress, weight, goals, measurements, or check-ins.</p>
          <details class="secure-link-details">
            <summary>Show secure pairing link</summary>
            <code class="payload-box">${escapeHtml(payload)}</code>
          </details>
          <div class="pairing-actions">
            <button class="button primary" type="button" data-action="copy-code" data-id="${code.id}">Copy secure pairing link</button>
            <button class="button danger" type="button" data-action="revoke-code" data-id="${code.id}">Revoke link</button>
          </div>
        </div>
      </div>
    `;
    pairingDialog.showModal();
  }

  function createMealRow(meal = {}) {
    const row = document.createElement("div");
    row.className = "meal-row";
    row.innerHTML = `
      <label>
        Day
        <input name="day" placeholder="Monday" value="${escapeAttribute(meal.day || "")}" required>
      </label>
      <label>
        Meal
        <input name="meal" placeholder="Breakfast" value="${escapeAttribute(meal.meal || "")}" required>
      </label>
      <label>
        Meal time
        <input name="time" placeholder="8:00 AM" value="${escapeAttribute(meal.time || "")}">
      </label>
      <label>
        Guidance
        <input name="items" placeholder="Greek yogurt bowl; berries" value="${escapeAttribute(meal.items || "")}" required>
      </label>
      <label>
        Optional swaps
        <input name="swaps" placeholder="Swap yogurt for cottage cheese" value="${escapeAttribute(meal.swaps || "")}">
      </label>
      <button class="remove-meal" type="button" aria-label="Remove meal row">-</button>
    `;
    row.querySelector(".remove-meal").addEventListener("click", () => row.remove());
    return row;
  }

  function readMealRows() {
    return [...mealRows.querySelectorAll(".meal-row")]
      .map((row) => ({
        day: row.querySelector('[name="day"]').value.trim(),
        meal: row.querySelector('[name="meal"]').value.trim(),
        time: row.querySelector('[name="time"]').value.trim(),
        items: row.querySelector('[name="items"]').value.trim(),
        swaps: row.querySelector('[name="swaps"]').value.trim(),
      }))
      .filter((meal) => meal.day && meal.meal && meal.items);
  }

  function normalizeState(raw) {
    const fallback = { plans: [], patients: [], codes: [], selectedPlanId: null };
    const next = { ...fallback, ...raw };
    next.plans = (next.plans || []).map((plan) => ({
      id: plan.id || crypto.randomUUID(),
      title: plan.title || "Untitled meal plan",
      effective: plan.effective || "This week",
      note: plan.note || "",
      meals: normalizeMeals(plan.meals),
      createdAt: plan.createdAt || new Date().toISOString(),
      updatedAt: plan.updatedAt || plan.createdAt || new Date().toISOString(),
    }));
    next.patients = (next.patients || []).map((patient) => ({
      id: patient.id || crypto.randomUUID(),
      label: patient.label || "Access slot",
      planId: patient.planId || "",
      status: patient.status || "ready",
      createdAt: patient.createdAt || new Date().toISOString(),
    }));
    next.codes = (next.codes || []).map((code) => ({
      id: code.id || crypto.randomUUID(),
      patientId: code.patientId,
      planId: code.planId,
      token: code.token || shortToken(),
      status: code.status || (code.revokedAt ? "revoked" : "active"),
      createdAt: code.createdAt || new Date().toISOString(),
      expiresAt: code.expiresAt || new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      revokedAt: code.revokedAt || null,
    }));
    return next;
  }

  function normalizeMeals(value) {
    if (Array.isArray(value)) {
      return value.map((meal) => ({
        day: meal.day || "Any day",
        meal: meal.meal || "Meal",
        time: meal.time || "",
        items: meal.items || meal.description || "",
        swaps: meal.swaps || meal.notes || "",
      }));
    }

    if (typeof value !== "string") return defaultMealRows();
    let currentDay = "Any day";
    const meals = [];
    value.split("\n").map((line) => line.trim()).filter(Boolean).forEach((line) => {
      if (!line.includes("|")) {
        currentDay = line;
        return;
      }
      const parts = line.split("|").map((part) => part.trim());
      meals.push({
        day: currentDay,
        meal: parts[0] || "Meal",
        time: parts[1] || "",
        items: parts[2] || "",
        swaps: parts[3] || "",
      });
    });
    return meals.length ? meals : defaultMealRows();
  }

  function samplePlan(kind) {
    const isProtein = kind === "protein";
    return {
      id: crypto.randomUUID(),
      title: isProtein ? "High Protein Basics" : "Steady Week Meal Plan",
      effective: isProtein ? "Next 7 days" : "This week",
      note: isProtein
        ? "Simple protein-forward meals with portion guidance and vegetarian swaps. No calorie or macro tracking."
        : "Simple meals, portions, timing, and swaps. No calories, macros, food database, or app progress sharing.",
      meals: isProtein ? [
        { day: "Monday", meal: "Breakfast", time: "8:00 AM", items: "Egg scramble; spinach; whole-grain toast", swaps: "Swap eggs for tofu scramble" },
        { day: "Monday", meal: "Lunch", time: "12:30 PM", items: "Turkey bowl; greens; avocado", swaps: "Use beans for a vegetarian option" },
        { day: "Tuesday", meal: "Dinner", time: "6:30 PM", items: "Chicken plate; roasted vegetables; potatoes", swaps: "Swap chicken for tempeh" },
      ] : defaultMealRows(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
  }

  function defaultMealRows() {
    return [
      { day: "Monday", meal: "Breakfast", time: "8:00 AM", items: "Greek yogurt bowl; berries; chia seeds", swaps: "Swap yogurt for cottage cheese" },
      { day: "Monday", meal: "Lunch", time: "12:30 PM", items: "Chicken salad wrap; cucumber slices", swaps: "Swap chicken for tofu" },
      { day: "Monday", meal: "Dinner", time: "6:30 PM", items: "Salmon plate; roasted vegetables; small rice portion", swaps: "Swap salmon for beans or turkey" },
      { day: "Tuesday", meal: "Breakfast", time: "8:00 AM", items: "Oatmeal; walnuts; berries", swaps: "Use eggs and toast if preferred" },
    ];
  }

  function filteredPlans() {
    return state.plans.filter((plan) => matchesSearch([plan.title, plan.effective, plan.note]));
  }

  function filteredPatients() {
    return state.patients.filter((patient) => matchesSearch([patient.label, findPlan(patient.planId)?.title || ""]));
  }

  function filteredCodes() {
    return state.codes.filter((code) => matchesSearch([findPatient(code.patientId)?.label || "", findPlan(code.planId)?.title || "", code.token, code.status]));
  }

  function matchesSearch(values) {
    if (!searchTerm) return true;
    return values.some((item) => String(item).toLowerCase().includes(searchTerm));
  }

  function groupMealsByDay(meals) {
    const groups = [];
    meals.forEach((meal) => {
      let group = groups.find((item) => item.day === meal.day);
      if (!group) {
        group = { day: meal.day, items: [] };
        groups.push(group);
      }
      group.items.push(meal);
    });
    return groups;
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

  function activePairingCodes() {
    return state.codes.filter((code) => code.status === "active" && !isExpired(code));
  }

  function expiredCodes() {
    return state.codes.filter((code) => code.status === "active" && isExpired(code));
  }

  function revokeCode(id) {
    const code = findCode(id);
    if (!code) return;
    code.status = "revoked";
    code.revokedAt = new Date().toISOString();
    if (activePairingCodeId === id) activePairingCodeId = null;
    if (pairingDialog.open) pairingDialog.close();
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

  function statusLabel(patient, latestCode) {
    if (!patient.planId) return "Unassigned";
    if (latestCode) return `Code expires ${formatDate(latestCode.expiresAt)}`;
    if (patient.status === "paired") return "Paired";
    return "Ready for pairing link";
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

  function nextPlanId(currentPlanId) {
    if (state.plans.length === 0) return "";
    const index = state.plans.findIndex((plan) => plan.id === currentPlanId);
    return state.plans[(index + 1) % state.plans.length].id;
  }

  function countMeals(meals) {
    return Array.isArray(meals) ? meals.length : 0;
  }

  function findPlan(id) {
    return state.plans.find((plan) => plan.id === id);
  }

  function findPatient(id) {
    return state.patients.find((patient) => patient.id === id);
  }

  function findCode(id) {
    return state.codes.find((code) => code.id === id);
  }

  function isExpired(code) {
    return new Date(code.expiresAt).getTime() <= Date.now();
  }

  function loadState() {
    try {
      return JSON.parse(localStorage.getItem(storageKey) || "{}");
    } catch {
      return {};
    }
  }

  function persist() {
    state.selectedPlanId = selectedPlanId;
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
    return String(value)
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
