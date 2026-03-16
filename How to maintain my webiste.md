#julia #website #franklin


# How to maintain my website

## Prerequisite 
### Julia
```
julia> versioninfo()
Julia Version 1.7.1
Commit ac5cc99908 (2021-12-22 19:35 UTC)
Platform Info:
  OS: macOS (arm64-apple-darwin21.2.0)
  CPU: Apple M1
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-12.0.1 (ORCJIT, cyclone)
```

### Franklin  
```
(@v1.7) pkg> st Franklin
      Status `~/.julia/environments/v1.7/Project.toml`
  [713c75ef] Franklin v0.10.72
```

## 1. Go to your franklin project directory, which should be like:
```shell 
$ tree -L 1
.
├── 404.md
├── Project.toml
├── __site
├── _assets
├── _css
├── _layout
├── _libs
├── _rss
├── config.md
├── index.html
├── lecture.md
├── notebooks
├── notes.md
├── profile.md
├── publications.md
├── research.md
└── utils.jl
```
Now (10.9.2022), the directory is located in 
```bash
cd /Users/siida/Dropbox/00-personal_data/00-shinji-vault/09-websites/02-mywebsite_byfranklin.
```

## 2. Execute Julia, and do the following in Julia REPL:
```julia 
using Franklin
julia> serve() # Or serve(port=8000)
```
- Your website is launched locally.
- The website launched is interactively updated while you modify content. So, this is a good way to check what you wrote.

## 3. Build locally when you want to verify the production output
```bash
julia --project=. build.jl
```

This generates `__site` and copies `CNAME` into the output.

## 4. Deploy with GitHub Actions
Push changes to `main`.

```bash
git push origin main
```

GitHub Actions will:
- instantiate the Julia project,
- run `julia --project=. build.jl`,
- upload `__site`,
- deploy it to GitHub Pages.

## 5. GitHub Pages settings
- Go to https://github.com/physicshinzui/my-website/settings/pages
- Set the source to `GitHub Actions`
- Confirm the custom domain is `s-iida.com`
- Visit `s-iida.com` after the workflow finishes



---

## How to add Google analytics to my website 
Put the following lines just after `<head>` line (maybe, in index.html).
```
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-154771635-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-154771635-1');
</script>
```

Then, I can see the statistics of the website in:
https://analytics.google.com/analytics/web/#/report-home/a154771635w218384735p208236512



## Change fonts
Change the font of section h1, h2, ...
```css
.franklin-content a {
  text-decoration: none;
  /* Shinji added to change the font of h1, h2, ... */
  font-family: "Avenir Next" <--IMPORTANT
}
```

For contents
```css
.franklin-content {
  position: relative;
  padding-left: 12.5%;
  padding-right: 12.5%;
  line-height: 1.35em;
  /* Shinji's favourite font */
  font-family: "Avenir Next"  <--IMPORTANT
}
```

For footer
```css
.page-foot {
  font-size: 80%;
  /* font-family: Arial, serif; */
  font-family: "Avenir Next"  <--IMPORTANT
  color: #a6a2a0;
  text-align: center;
  margin-top: 6em;
  border-top: 1px solid lightgrey;
  padding-top: 2em;
  margin-bottom: 4em;
}
```
