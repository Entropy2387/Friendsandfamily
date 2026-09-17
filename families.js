(() => {
  const grid = document.getElementById('familyGrid');
  const status = document.getElementById('familyStatus');
  if (!grid || !status) return;
  const cfg = window.APP_CONFIG || {};
  if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) { status.textContent = 'Family groups are temporarily unavailable.'; return; }
  const client = supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[ch]));
  async function loadFamilies(){
    const {data,error}=await client.rpc('list_households_public');
    if(error){ console.error(error); status.textContent='Family groups could not be loaded right now.'; return; }
    if(!data || !data.length){ status.textContent='No family groups have been added yet.'; return; }
    grid.innerHTML=data.map(h=>`<article class="family-card"><div class="family-icon">♡</div><h3>${escapeHtml(h.name)}</h3><div class="member-list">${(h.member_names||[]).map(n=>`<span>${escapeHtml(n)}</span>`).join('')}</div></article>`).join('');
    status.hidden=true; grid.hidden=false;
  }
  loadFamilies();
})();
