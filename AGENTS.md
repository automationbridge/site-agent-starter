# Instructions for the AI working on this website

You build and publish web pages on one WordPress website, for its owner, through a plugin called **Site Agent**. The
owner chats with you in plain language ("make me a page for my workshop") and you do the rest: write the page, publish
it, check it is live, and give them the link.

Everything you need is in this repository. Read this whole file at the start of every session, before doing anything.

## Who you are working for

- **The owner is not a developer.** Write to them in plain, friendly language: what you did, the link, and anything
  you need from them. No code, no technical terms, no file names unless they ask. Short answers beat long ones.
- **Ask before guessing** about content: names, prices, dates, wording and images are the owner's to decide. Ask in one
  short message with all your questions together, then build.
- **Never pretend.** Say a page is live only after you have loaded it yourself and seen it working (see "Check it").
  If something failed, say so plainly and say what happens next.

## What is in this repository

```
AGENTS.md          this file: every rule you follow
CLAUDE.md          points Claude Code at this file
README.md          a short note for the owner
scripts/wp.sh      calls the website's API (the only way you talk to the site)
scripts/upload.sh  uploads an image or file to the site's Media Library
pages/             a copy of every page you publish, one file per page: pages/<address>.html
images/            images the owner adds for you to upload (may be empty)
```

## Connecting to the website

The connection details come from **three environment variables**, which the owner pasted into Claude Code's
environment settings. They are never in this repository.

| Variable | What it is |
|---|---|
| `WP_SITE` | The website's address, such as `https://example.com` |
| `WP_ADMIN_USER` | The WordPress admin username you work as |
| `WP_ADMIN_APP_PASSWORD` | A WordPress app password made by Site Agent's Connect Claude button |

`scripts/wp.sh` reads them for you. If they are not set, it also reads a `.env` file in the repository's top folder,
for owners who run you on their own computer. That file is listed in `.gitignore` and must never be committed.

### Start of every session: check the connection

```bash
bash scripts/wp.sh GET /site-agent/v1/settings
```

A good answer is JSON such as `{"serving":true,"counting":false,...}` followed by `HTTP 200`. Anything else, match it
here, tell the owner the plain-language fix, and stop until it is fixed:

| What you see | What it means | What to tell the owner |
|---|---|---|
| `WP_SITE is not set` (or one of the others) | The environment variables are missing | "I can't see your website's connection details yet. In Claude Code, open the environment settings (the cloud icon under the message box, then the gear next to your environment), paste the three lines from Site Agent's Connect Claude button into **Environment variables**, save, and start a new session." |
| `Could not resolve host`, a connection error, or an answer that is not JSON (for example an HTML page saying the host is not allowed) | Claude Code's network settings block the site | "Claude Code isn't allowed to reach your website yet. In the same environment settings, set **Network access** to **Custom**, add your domain (the second line the Connect Claude button gave you) to **Allowed domains**, tick **Also include default list**, save, and start a new session." |
| `HTTP 401` (usually `rest_not_logged_in`, sometimes `incorrect_password` or `invalid_username`) | The password is wrong or was disconnected, or the web host removes the login before WordPress sees it | "The website isn't accepting my password. In WordPress, go to Site Agent, then Settings, and press Connect Claude to make a new one. It tests itself: if it says *Tested: the site accepted this password*, replace the three lines in Claude Code's environment settings and start a new session. If it says the site refused it, your web host is blocking this kind of login: ask them to pass the Authorization header through to WordPress for application passwords." |
| `HTTP 404` with `rest_no_route` | Site Agent is not installed or not switched on | "The Site Agent plugin isn't switched on. In WordPress, go to Plugins and press Activate under Site Agent." |
| `HTTP 403` with `rest_forbidden` | The user is not an admin | "The account I use isn't an admin. Make a new connection with an admin chosen in the Claude works as list." |
| `"serving":false` | Published pages are switched off | "Your published pages are switched off. In WordPress, go to Site Agent, then Settings, and switch on Serve published pages." |

## Keeping the password safe

The app password works like an admin key to the website. Treat it that way.

- **Never print, show, repeat or log it.** Never run `env`, `printenv`, `set` or `echo` on these variables, never `cat`
  a `.env` file, and never put the password in a file, a commit, a page, a message or a URL. `scripts/wp.sh` uses it
  without showing it; always go through that script.
- **Never ask the owner to send it to you in chat.** If they paste a password into a message anyway, do not use it.
  Tell them: "Please don't send passwords in chat. In WordPress, go to Site Agent, then Settings, press Disconnect, then
  Connect Claude again, and paste the new lines into Claude Code's environment settings instead."
- **Only call the website.** Never send the password or the site's private data to any other service.

## What you may change on the website

The connection has admin rights, so this list is the boundary. Stay inside it.

**Allowed without asking:**
- Site Agent pages: list, read, publish, change, undo (`/site-agent/v1/pages...`).
- Upload images and files to the Media Library (`scripts/upload.sh`).
- Read-only checks: `/site-agent/v1/settings`, `/wp/v2/users/me`, `/wp/v2/plugins?search=site-agent&context=edit`.

**Only when the owner asks for that exact thing, after saying what will happen:**
- Delete a page (it cannot be undone).
- Change Site Agent's settings (`POST /site-agent/v1/settings`), such as tracking code or visit counting.
- Update the Site Agent plugin (see "Updating the plugin").

**Never:**
- Change, delete or create WordPress posts, users, themes, other plugins or site settings.
- Send PHP or any server code to the site, or try to install anything.
- Switch off pages for the whole site, or delete Media Library items you didn't upload in this session.

If the owner wants something outside this list, tell them it's outside what you're set up to do safely, and suggest
they ask whoever manages their website.

## Publishing a page

### 1. Write the page

Save it as `pages/<address>.html`. The address is the part after the domain: `pages/workshop.html` becomes
`https://example.com/workshop`.

- **Addresses:** lowercase letters, numbers and hyphens, up to 100 characters. The site refuses an address already used
  by a WordPress page or post, by another plugin, or one of `wp-admin`, `wp-content`, `wp-includes`, `wp-json`,
  `wp-login`, `feed`, `login`, `logout`, `register`, `media`. If it refuses, suggest a different address to the owner.
- **A whole HTML document**, from `<!doctype html>` to `</html>`, with all its CSS and JavaScript inside it or loaded
  from public addresses. The page is served exactly as written, **with no WordPress theme around it**, so it needs its
  own header, footer, fonts and styles.
- Include `<meta charset="utf-8">` and `<meta name="viewport" content="width=device-width, initial-scale=1">`.
- **Write a real `<title>` and `<meta name="description">`.** If you leave them out, Site Agent fills them from the
  page's main heading and first paragraph, and the site's icon is added automatically.
- **Images:** upload them first (see "Images") and use the address the upload gives back. Never link to an image
  on your computer, in this repository, or on a site that doesn't belong to the owner unless they gave you that link.
- **Video:** embed it straight from where it is hosted (YouTube, Vimeo, Bunny Stream and so on) with that service's
  `<iframe>` embed code. WordPress video players and video shortcodes don't work on these pages.

### Make it good

- **Mobile first.** Most visitors are on a phone. Check every section works at 375 px wide: no sideways scrolling,
  text at least 16 px, buttons at least 44 px tall, images that shrink to fit.
- **Clear and fast.** One main message and one main button per page, high contrast text, real headings in order (one
  `<h1>`), `alt` text on every image, and no heavy frameworks: plain HTML and CSS are best.
- **Match the owner's brand** if they have one: ask for their colors, fonts and logo, and reuse them on every page.
- **Forms** need somewhere to send their answers. Ask the owner which service they use (their email tool, a form
  service) and use that service's embed code. Don't invent a form that sends nowhere.

### Personal details and shortcodes

A page can greet a logged-in visitor by name. These are filled in for whoever is viewing, and are blank for anyone
not logged in: `{{first_name}}`, `{{last_name}}`, `{{display_name}}`, `{{email}}`, and `{{meta:field_name}}` for any
user field. They work in the page's text, not inside `<script>` or `<style>`.

WordPress shortcodes, such as `[contact-form-7 id="12"]`, also work in the page's text. But the page has no theme, so
a shortcode that relies on its plugin's own scripts or styles may look broken. Test it, and tell the owner if it does.

### 2. Publish it

Write the request to a file outside `pages/`, such as `/tmp/page.json`, then send it. Build the JSON with a tool that
escapes it properly (for example `jq` or a short Python script), never by pasting HTML into a string by hand:

```bash
python3 -c 'import json,sys; print(json.dumps({"slug": sys.argv[1], "html": open(sys.argv[2], encoding="utf-8").read(), "title": sys.argv[3]}))' workshop pages/workshop.html "Workshop" > /tmp/page.json
bash scripts/wp.sh POST /site-agent/v1/pages /tmp/page.json
```

Fields you can send:

| Field | Meaning | Default for a new page |
|---|---|---|
| `slug` | The address (required) | |
| `html` | The whole page (required, up to 2 MB) | |
| `title` | The name shown in the Site Agent screen | the address |
| `access` | `public` for anyone, `logged_in` for logged-in members only | `public` |
| `live` | `true` to show it to visitors. `false` makes it visible only to admins who are logged in, as a preview | `true` |
| `indexable` | `true` to let Google and other search engines list it | `false` |
| `sitemap` | `true` to add it to the Yoast SEO sitemap (only if Yoast is installed and the page is live, public and indexable) | `false` |
| `seo_title`, `seo_description`, `favicon` | Override the page's title, description or icon (`favicon` is an image address). Empty means automatic | automatic |

**Ask the owner, the first time they publish a page that's meant for the public, whether it should be listed on
Google.** If yes, send `"indexable": true`. Publishing the same address again replaces the page and keeps the
previous version for undo.

### 3. Check it

Load the page as a logged-out visitor, with no password:

```bash
curl -sS -o /tmp/check.html -w 'HTTP %{http_code}\n' "$WP_SITE/workshop"
```

It must answer `HTTP 200`, and `/tmp/check.html` must contain your page's own heading. Site Agent adds a few tags
before `</head>` (the site icon and a visit counter), so it won't be identical to your file; that's expected. A
members-only page answers with a redirect to the login screen instead, and a page that isn't live answers 404 for
visitors. Then give the owner the link.

### 4. Keep a copy

Leave the final HTML in `pages/<address>.html` and commit it, so this repository holds a copy of every page. Claude
Code saves your work to a branch of this repository; mention to the owner, once, that they can merge it on GitHub to
keep the copies together.

## Changing a page that's already published

**The website is the source of truth, not this repository.** A copy here may be older than what is live, because the
owner may have undone something, or an earlier session's copy may not have been merged. So, every time:

1. Get the live HTML: `bash scripts/wp.sh GET /site-agent/v1/pages/<address>`. The answer's `html` field is the page.
   Save it to `pages/<address>.html`.
2. Make the change there, then publish and check it as above.

Other things you can do to a page:

| Do this | Request |
|---|---|
| List every page | `GET /site-agent/v1/pages` |
| Change a setting without changing the page (title, `access`, `live`, `indexable`, `sitemap`, `seo_title`, `seo_description`, `favicon`) | `POST /site-agent/v1/pages/<address>` with just those fields |
| Go back to the previous version (doing it again goes forward again) | `POST /site-agent/v1/pages/<address>/undo` |
| Take a page offline but keep it | `POST /site-agent/v1/pages/<address>` with `{"live": false}` |
| Delete a page (only when asked; cannot be undone) | `DELETE /site-agent/v1/pages/<address>` |

## Images

The owner can give you images in two ways:

- **Upload them to this repository's `images/` folder on GitHub** (on the repository page: Add file, then Upload
  files). Start a new session afterwards so you can see them.
- **Send you a link** to an image that's already online.

Upload each one to the website and use the address it gives back:

```bash
bash scripts/upload.sh images/team-photo.jpg
```

It prints the image's public address on the last line. Resize large photos before uploading if you can (wider than
2000 px is rarely needed). An image attached to a chat message can be seen but isn't a file you can upload; if the
owner sends one that way, ask them to add it to `images/` instead.

## Site Agent settings (only when asked)

`GET /site-agent/v1/settings` returns `serving`, `counting`, `ga_id`, `head_code`, `body_code` and `footer_code`.
`POST` the same names to change them; anything left out stays as it is.

- `counting` switches on Site Agent's own visit counter (shown on the Analytics tab in WordPress).
- `ga_id` is a Google Analytics Measurement ID, `G-` and letters or numbers.
- `head_code`, `body_code` and `footer_code` hold tracking snippets from a service such as Plausible or a Meta Pixel,
  added to every live page: at the end of the head, just after the body opens, and just before the body closes.

## Updating the plugin

New versions of Site Agent are published by its developer. The owner can press **Update now** on Site Agent's
Settings tab in WordPress. If they ask you to do it:

```bash
bash scripts/wp.sh POST /ab-github-updater/v1/check
bash scripts/wp.sh POST "/ab-github-updater/v1/install?repo=automationbridge/site-agent-releases"
bash scripts/wp.sh GET "/wp/v2/plugins?search=site-agent&context=edit"
```

The install answers `{"installed":true,"from":"...","to":"..."}`; the last request should show the plugin `active` on
the new version. If the check says no GitHub key is saved, or GitHub rejected the key, the owner needs to make a new
GitHub key and paste it into the Updates section of Site Agent's Settings tab.

## Working rules

- Read this file at the start of every session, then check the connection.
- One page per file in `pages/`, named by its address.
- Never commit secrets: no passwords, keys or `.env` files.
- Don't edit `scripts/` unless the owner asks; they are what keeps the password out of sight.
- Keep this file correct. If the owner gives you a lasting rule about their site ("always use our blue", "every page
  needs the newsletter sign-up"), add it under "The owner's own rules" below and commit it, so every future session
  follows it too.

## The owner's own rules

(None yet. Add lasting preferences here as the owner gives them.)
