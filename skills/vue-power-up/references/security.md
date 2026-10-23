# Security (`VUE-SEC-*`)

Rules for the places a Vue/Nuxt app turns data into behaviour: template HTML, URLs, redirects, styles, client-visible state, cookies and server-side requests. Server input validation and auth are in `nuxt.md` (VUE-NUXT-011, VUE-NUXT-013, VUE-NUXT-015).

**Untrusted** means anything an attacker could influence:
- user input, URL and route params, query strings
- API responses carrying user-generated content
- cookies, `localStorage`
- third-party data.

Vue escapes `{{ }}` interpolation and attribute bindings for you. The rules below cover the cases where it can't.

---

### VUE-SEC-001 · Never bind untrusted content to `v-html`  `error`

**Why:**
- `v-html` inserts raw HTML, so `<img src=x onerror=…>` runs script in your origin: stored or reflected XSS.
- The Vue docs say user-provided HTML is never 100% safe outside a sandboxed iframe.
- Prefer rendering as text. If rich text is a real requirement, sanitize with an HTML sanitizer (e.g. DOMPurify) right before rendering, ideally also on the server when saving.
- Adding a sanitizer is a new dependency: **ask first**, and until then render as text.

**Source:** https://vuejs.org/guide/best-practices/security.html#html-injection · https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html

```vue
<!-- ❌ -->
<div v-html="user.bio" />

<!-- ✅ text (keeps line breaks) -->
<p class="whitespace-pre-line">{{ user.bio }}</p>

<!-- ✅ rich text, sanitizer approved by the user -->
<div v-html="safeBio" />
<!-- const safeBio = computed(() => DOMPurify.sanitize(user.value.bio)) -->
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** HTML that's trusted by construction: produced by your own build (markdown compiled at build time from repo files) or by your server's sanitizer, and documented as such at the binding.

---

### VUE-SEC-002 · Validate untrusted URLs before binding them to `href`, `src`, `action` or `formaction`  `error`

**Why:**
- Vue escapes attribute *values* but not their *meaning*. `:href="user.website"` with `javascript:alert(document.cookie)` runs script on click.
- Allow only expected schemes (`https:`, `http:`, `mailto:`), or same-origin relative paths.
- Sanitize on the backend when saving, too.

**Source:** https://vuejs.org/guide/best-practices/security.html#url-injection · https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html

```ts
// ❌ <a :href="profile.website">Website</a>

// ✅
function safeExternalUrl(raw: string): string | undefined {
  try {
    const url = new URL(raw)
    return ['https:', 'http:', 'mailto:'].includes(url.protocol) ? url.href : undefined
  } catch { return undefined }
}
const website = computed(() => safeExternalUrl(profile.value.website))
// <a v-if="website" :href="website" rel="noopener noreferrer nofollow" target="_blank">Website</a>
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** URLs built entirely from your own constants and route names.

---

### VUE-SEC-003 · Never compile or render untrusted content as a template, component, script or style block  `error`

**Why:**
- A Vue template can run arbitrary JavaScript, so a template string built from user input is full code execution. Examples: `template: '<div>' + input + '</div>'`, `compile(userString)`, or `<component :is="userChosenName">` resolving any global component.
- Binding a whole user-controlled `style` object, or user values to `on*` attributes, allows click-jacking and script injection.
- Bind specific, validated style properties instead.

**Source:** https://vuejs.org/guide/best-practices/security.html#rule-no-1-never-use-non-trusted-templates · https://vuejs.org/guide/best-practices/security.html#style-injection

```ts
// ❌
const Comp = defineComponent({ template: `<p>${comment.text}</p>` })
// <component :is="route.query.widget" />  <div :style="user.customStyle" />

// ✅
const widgets = { chart: ChartWidget, table: TableWidget } as const
const widget = computed(() => widgets[route.query.widget as keyof typeof widgets] ?? null)
// <component :is="widget" v-if="widget" />  <div :style="{ color: safeColor }" />
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-SEC-004 · Redirect only to validated same-origin paths  `error`

**Why:**
- A redirect target taken from the query (`?next=`, `?returnUrl=`) or other input enables phishing through your domain (open redirect).
- It can also run script: `window.location.href = 'javascript:…'`.
- Accept only relative paths that start with a single `/`. Reject `//evil.com`, `/\evil.com` and absolute URLs. Fall back to a default page.

**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html · https://nuxt.com/docs/4.x/api/utils/navigate-to

```ts
// ❌
await navigateTo(route.query.next as string, { external: true })
window.location.href = String(route.query.returnUrl)

// ✅
function safeRedirectPath(raw: unknown, fallback = '/'): string {
  if (typeof raw !== 'string') return fallback
  if (!raw.startsWith('/') || raw.startsWith('//') || raw.startsWith('/\\')) return fallback
  return raw
}
await navigateTo(safeRedirectPath(route.query.next, '/dashboard'))
```

**Applies:** Vue ≥ 3.0, Nuxt ≥ 3.0 · **Exceptions:** an allowlist of known external hosts, checked by parsing with `new URL()` and comparing `origin`.

---

### VUE-SEC-005 · Keep secrets and server-only data out of everything the client receives  `error`

**Why:**
- All of the following reaches every visitor:
  - client source and Vite `VITE_*` env vars
  - Nuxt `runtimeConfig.public` and `app.config`
  - the SSR payload: `useState`, Pinia state, `useFetch`/`useAsyncData` results.
- API keys, tokens and private fields (password hashes, internal notes, other users' emails) put there are leaked.
- Keep them on the server, and send the client only the fields it needs.

**Source:** https://vite.dev/guide/env-and-mode · https://nuxt.com/docs/4.x/guide/going-further/runtime-config · https://owasp.org/API-Security/editions/2023/en/0xa3-broken-object-property-level-authorization/

```ts
// ❌
const stripe = new Stripe(import.meta.env.VITE_STRIPE_SECRET_KEY)
const { data: user } = await useFetch('/api/me') // handler returns the full DB row incl. passwordHash

// ✅ server/api/me.get.ts: return a DTO
const { id, name, email, avatarUrl } = row
return { id, name, email, avatarUrl }
```

**Applies:** Vue ≥ 3.0, Nuxt ≥ 3.0 · **Exceptions:** values that are public by design (publishable keys, public site config).

---

### VUE-SEC-006 · Don't make server-side requests to user-supplied URLs (SSRF)  `error`

**Why:**
- A server route that does `$fetch(body.url)` (link previews, webhooks, image proxies, "import from URL") lets attackers make your server call internal services: cloud metadata (`169.254.169.254`), databases, admin panels.
- Allowlist hosts. If arbitrary URLs are a product requirement, resolve and block private/link-local ranges, and disable redirects.

**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html

```ts
// ❌ server/api/preview.post.ts
const { url } = await readBody(event)
return $fetch(url)

// ✅
const ALLOWED_HOSTS = new Set(['images.example-cdn.com'])
const { url } = await readValidatedBody(event, isPreviewRequest)
const target = new URL(url)
if (target.protocol !== 'https:' || !ALLOWED_HOSTS.has(target.hostname)) {
  throw createError({ statusCode: 400, statusMessage: 'URL not allowed' })
}
return $fetch(target.href, { redirect: 'manual' })
```

**Applies:** Nuxt/Nitro server routes, any Node backend · **Exceptions:** fixed URLs from config.

---

### VUE-SEC-007 · Store session credentials in `httpOnly`, `secure`, `sameSite` cookies set by the server, not in `localStorage`  `warn`

**Why:**
- Tokens in `localStorage` or in JS-readable cookies can be stolen by any XSS.
- Session cookies should be set by the server with `httpOnly` (no JS access), `secure` (HTTPS only) and `sameSite: 'lax'` or `'strict'` (CSRF mitigation).
- Nuxt's `useCookie` creates JS-readable cookies. Use it for preferences, not credentials.

**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html · https://nuxt.com/docs/4.x/api/composables/use-cookie

```ts
// ❌
localStorage.setItem('token', token)
useCookie('auth_token').value = token

// ✅ server/api/login.post.ts
setCookie(event, 'session', sessionId, { httpOnly: true, secure: true, sameSite: 'lax', path: '/', maxAge: 60 * 60 * 8 })
```

**Applies:** Vue ≥ 3.0, Nuxt ≥ 3.0 · **Exceptions:** short-lived in-memory tokens in a pure SPA talking to a third-party API that requires bearer tokens. Keep them in memory, not storage.

---

### VUE-SEC-008 · Protect cookie-authenticated state-changing endpoints against CSRF  `warn`

**Why:**
- When auth rides on cookies, a malicious site can submit requests that carry the user's cookies.
- `sameSite: 'lax'`/`'strict'` session cookies block most cross-site POSTs.
- Also accept state changes only through non-GET methods (method-suffixed handlers such as `.post.ts`), and check `Origin` or use a CSRF token for sensitive actions. The Vue docs leave CSRF to the backend, and this is that backend.

**Source:** https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html · https://vuejs.org/guide/best-practices/security.html#backend-coordination

```ts
// ❌ server/api/account/delete.get.ts (state change on GET)

// ✅ server/api/account/delete.post.ts
const origin = getRequestHeader(event, 'origin')
if (origin && origin !== getRequestURL(event).origin) throw createError({ statusCode: 403 })
```

**Applies:** Nuxt/Nitro server routes with cookie auth · **Exceptions:** APIs authenticated only by an `Authorization` header (not sent automatically by browsers).
