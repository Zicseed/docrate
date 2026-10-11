// Serves /p/<id>: a share-preview page (title/og tags) that forwards to /professors/<id>.
// Crawlers don't run JS, so the professor's name must be in the HTML we return.
const esc = s => s.replace(/[&<>"']/g, c => `&#${c.charCodeAt(0)};`);

// Name from Supabase (null if unknown or hidden). Settings come from config.js so they live in one place.
async function professorName(origin, id) {
  const cfg = await (await fetch(`${origin}/config.js`)).text();
  const url = cfg.match(/url:\s*"([^"]+)"/)?.[1], key = cfg.match(/anonKey:\s*"([^"]+)"/)?.[1];
  const res = await fetch(`${url}/rest/v1/rpc/professor_public_name`, { method: "POST", headers: { apikey: key, "Content-Type": "application/json" }, body: JSON.stringify({ p_id: id }) });
  return res.ok ? await res.json() : null;
}

export default async (req) => {
  const { origin, pathname } = new URL(req.url);
  const id = decodeURIComponent(pathname.split("/")[2] || "");
  if (!/^[\w-]{1,80}$/.test(id)) return Response.redirect(`${origin}/`, 302);

  let name = null;
  try { name = await professorName(origin, id); } catch (e) { console.error("profile-share:", e); }
  const title = esc(name ? `${name} | DocRate` : "DocRate");
  const desc = esc(name ? `Read anonymous student reviews and ratings for ${name} on DocRate.` : "Know your professors before you take their class.");
  const target = `/professors/${id}`, img = "https://doc-rate.com/assets/docrate-share.png";

  return new Response(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title>
<meta name="description" content="${desc}">
<meta property="og:type" content="website"><meta property="og:site_name" content="DocRate">
<meta property="og:title" content="${title}"><meta property="og:description" content="${desc}">
<meta property="og:url" content="https://doc-rate.com/p/${id}"><meta property="og:image" content="${img}"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630"><meta property="og:image:type" content="image/png">
<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="${title}"><meta name="twitter:description" content="${desc}"><meta name="twitter:image" content="${img}">
<link rel="canonical" href="https://doc-rate.com/p/${id}"><script>location.replace("${target}");</script><meta http-equiv="refresh" content="1;url=${target}"></head>
<body style="font:16px system-ui;background:#0e1d2b;color:white;padding:3rem">Opening ${name ? esc(name) : "DocRate"}… <a style="color:#39d6e5" href="${target}">Continue to profile</a></body></html>`,
    { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" } });
};

export const config = { path: "/p/*" };
