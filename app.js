
(() => {
  const cfg = window.APP_CONFIG || {};
  const status = document.getElementById("status");
  const form = document.getElementById("profileForm");

  function setStatus(message, type = "") {
    status.textContent = message;
    status.className = "status" + (type ? " " + type : "");
  }

  if (!cfg.supabaseUrl || cfg.supabaseUrl.includes("YOUR-PROJECT") ||
      !cfg.supabaseAnonKey || cfg.supabaseAnonKey.includes("YOUR_PUBLIC")) {
    setStatus("Site setup isn’t finished yet. Supabase details are missing from config.js.", "error");
    return;
  }

  const token = new URLSearchParams(window.location.search).get("token");
  if (!token) {
    setStatus("This edit link is missing its private token.", "error");
    return;
  }

  const client = supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);

  const fields = [
    "name","birthday","address","phone","email","favourite_flower",
    "favourite_treat","favourite_drink","hobbies","likes","dislikes"
  ];

  function fill(data) {
    fields.forEach(k => {
      const el = document.getElementById(k);
      if (el) el.value = data[k] ?? "";
    });
    document.getElementById("pageTitle").textContent = `${data.name} — your details`;
    form.hidden = false;
  }

  async function load() {
    setStatus("Loading your profile…");
    const { data, error } = await client.rpc("get_person_by_token", { p_token: token });
    if (error || !data || data.length === 0) {
      setStatus("This link is invalid or has expired.", "error");
      return;
    }
    fill(data[0]);
    setStatus("Loaded. Make any changes below.");
  }

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    setStatus("Saving…");
    const payload = {
      p_token: token,
      p_address: document.getElementById("address").value.trim(),
      p_phone: document.getElementById("phone").value.trim(),
      p_email: document.getElementById("email").value.trim(),
      p_favourite_flower: document.getElementById("favourite_flower").value.trim(),
      p_favourite_treat: document.getElementById("favourite_treat").value.trim(),
      p_favourite_drink: document.getElementById("favourite_drink").value.trim(),
      p_hobbies: document.getElementById("hobbies").value.trim(),
      p_likes: document.getElementById("likes").value.trim(),
      p_dislikes: document.getElementById("dislikes").value.trim()
    };

    const { data, error } = await client.rpc("update_person_by_token", payload);
    if (error || data !== true) {
      console.error(error);
      setStatus("I couldn’t save that. Please try again.", "error");
      return;
    }
    setStatus("Saved ✓", "success");
  });

  load();
})();
