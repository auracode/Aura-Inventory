// A USB scanner enters a barcode followed by Enter. Stock is only written on Save.
document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("[data-inventory-batch]");
  if (!form) return;
  const input = form.querySelector("[data-scan-input]");
  const lines = form.querySelector("[data-barcode-lines]");
  const list = form.querySelector("[data-scan-list]");
  const feedback = form.querySelector("[data-scan-feedback]");
  const count = form.querySelector("[data-scan-count]");
  const save = form.querySelector("[data-save-batch]");
  const timesField = form.querySelector("[data-scan-times]");
  const itemSelect = form.querySelector("[name='batch[item_id]']");
  const rows = lines.value.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  let times = JSON.parse(timesField.value || "{}");
  let queue = Promise.resolve();
  let pending = 0;

  function render() {
    lines.value = rows.join("\n");
    timesField.value = JSON.stringify(times);
    count.textContent = rows.length;
    list.replaceChildren();
    rows.forEach((barcode, index) => {
      const li = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = barcode + " ";
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", "Remove " + barcode);
      remove.addEventListener("click", () => {
        rows.splice(index, 1);
        delete times[barcode];
        feedback.textContent = barcode + ": removed from this batch.";
        render();
        input.focus();
      });
      li.append(label, remove);
      list.append(li);
    });
    if (itemSelect) {
      // Keep the select submitted, while preventing changes to a populated batch.
      itemSelect.dataset.lockedValue = rows.length ? itemSelect.value : "";
    }
    save.disabled = pending > 0 || rows.length === 0;
  }

  if (itemSelect) itemSelect.addEventListener("change", () => {
    if (itemSelect.dataset.lockedValue) {
      itemSelect.value = itemSelect.dataset.lockedValue;
      feedback.textContent = "Remove all scanned entries or save this batch before changing its item.";
    }
  });

  function enqueue() {
    const barcode = input.value.trim();
    if (!barcode) return;
    const scannedAt = new Date().toISOString();
    const itemId = itemSelect ? itemSelect.value : "";
    input.value = "";
    pending++;
    save.disabled = true;
    if (itemSelect) itemSelect.disabled = true;
    queue = queue.then(async () => {
      if (rows.includes(barcode)) {
        feedback.textContent = barcode + ": already in this batch.";
        return;
      }
      const query = new URLSearchParams({ barcode, direction: form.dataset.direction, item_id: itemId });
      try {
        const response = await fetch(form.dataset.checkUrl + "?" + query, { headers: { Accept: "application/json" }, credentials: "same-origin" });
        if (!response.ok) throw new Error("Scan check failed");
        const result = await response.json();
        if (result.accepted) {
          rows.push(barcode);
          times[barcode] = scannedAt;
          feedback.textContent = barcode + ": added — " + result.item_name;
        } else {
          feedback.textContent = barcode + ": " + result.error;
        }
      } catch (_) {
        feedback.textContent = barcode + ": could not check this scan. Please scan it again.";
      }
    }).finally(() => {
      pending--;
      if (itemSelect) itemSelect.disabled = pending > 0;
      render();
    });
    input.focus();
  }

  form.querySelector("[data-scanner]").hidden = false;
  form.querySelector("[data-manual-entry]").hidden = true;
  form.querySelector("[data-add-scan]").addEventListener("click", enqueue);
  input.addEventListener("keydown", event => {
    if (event.key === "Enter") { event.preventDefault(); enqueue(); }
  });
  form.addEventListener("submit", event => {
    if (pending || input.value.trim() || rows.length === 0) {
      event.preventDefault();
      feedback.textContent = "Add the pending barcode and wait for scan checks before saving.";
      input.focus();
      return;
    }
    save.disabled = true;
    save.value = "Saving…";
  });
  render();
  input.focus();
});