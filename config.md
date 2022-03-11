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
ignore = ["node_modules/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "Shinji's website"
website_descr = "Shinji's notes"
website_url   = "https://physicshinzui.github.io/"
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

\newcommand{\key}[1]{
  @@admonition
    @@key
      @@title 💡 Review of The Key Ideas@@ 
      @@content #1 @@ 
    @@
  @@
}