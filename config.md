<!--
Add here global page variables to use throughout your website.
-->
+++
author = "Shinji Iida"
mintoclevel = 2

# Add here files or directories that should be ignored by Franklin, otherwise
# these files might be copied and, if markdown, processed by Franklin which
# you might not want. Indicate directories by ending the name with a `/`.
# Base files such as LICENSE.md and README.md are ignored by default.
ignore = ["node_modules/", "drafts/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "Shinji Iida"
website_descr = "Research notes, publications, and profile of Shinji Iida, a computational biophysicist."
website_url   = "https://s-iida.com"
website_image = "/assets/IMG_3089.jpg"
twitter_handle = "@_siida_"
ga_measurement_id = "G-K27NB3FXGB"
giscus_repo = "physicshinzui/my-website"
giscus_repo_id = "R_kgDOG-cplw"
giscus_category = "General"
giscus_category_id = "DIC_kwDOG-cpl84C5V4o"
giscus_mapping = "pathname"
giscus_theme = "catppuccin_latte"
giscus_lang = "en"
+++

<!--
Add here global latex commands to use throughout your pages.
-->
\newcommand{\R}{\mathbb R}
\newcommand{\scal}[1]{\langle #1 \rangle}
<!-- \newcommand{\definition}[2]{
  @@definition
  **Definition**: (_!#1_)
  #2
  @@
} -->
\newcommand{\note}[1]{
  @@admonition
    @@note 
      @@title ⚠ Note@@ 
      @@content #1 @@ 
    @@
  @@
}

\newcommand{\def}[2]{
  @@admonition
    @@def 
      @@title Definition: (_!#1_)@@ 
      @@content #2 @@ 
    @@
  @@
}

\newcommand{\thm}[2]{
  @@admonition
    @@thm
      @@title Theorem: (_!#1_)@@
      @@content #2 @@
    @@
  @@
}

\newcommand{\lemma}[2]{
  @@admonition
    @@lemma
      @@title Lemma: (_!#1_)@@
      @@content #2 @@
    @@
  @@
}

\newcommand{\prop}[2]{
  @@admonition
    @@prop
      @@title Proposition: (_!#1_)@@
      @@content #2 @@
    @@
  @@
}

\newcommand{\results}[1]{
  @@admonition
    @@results
      @@title Results@@
      @@content #1 @@
    @@
  @@
}

\newcommand{\requirements}[1]{
  @@admonition
    @@requirements
      @@title Requirements@@
      @@content #1 @@
    @@
  @@
}

\newcommand{\derivation}[1]{
  @@admonition
    @@derivation
      @@title Derivation@@
      @@content #1 @@
    @@
  @@
}

\newcommand{\proof}[1]{
  @@admonition
    @@proof
      @@title Proof@@
      @@content #1 @@
    @@
  @@
}

\newcommand{\key}[1]{
  @@admonition
    @@key
      @@title 💡 Review of The Key Ideas@@ 
      @@content #1 @@ 
    @@
  @@
}
