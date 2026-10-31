# Publish this project to GitHub

You can publish this full project in either of two ways.

## Option 1: GitHub website (no command line required)

1. Extract the ZIP archive on your computer.
2. Sign in at <https://github.com/new> and create a **Public** repository named `clinical-trial-efficacy-safety-r`.
3. Leave "Add a README file", `.gitignore`, and license selections **unchecked**, since this repository already contains those files.
4. After creating the empty repository, choose **uploading an existing file**.
5. Upload the **contents of the extracted project folder**, preserving the directory structure; do not upload the ZIP as a single file.
6. Commit the files and confirm the README and the two preview figures appear on the repository front page.

GitHub's browser uploader may not preserve nested folder structures in all browsers. If nested folders don't upload correctly, use Option 2.

## Option 2: GitHub CLI (recommended for multi-folder projects)

1. Install Git and the [GitHub CLI](https://cli.github.com/).
2. Open a terminal in the extracted `clinical-trial-efficacy-safety-r` directory.
3. Execute:

```bash
gh auth login
git init
git add .
git commit -m "Initialize synthetic clinical trial analysis project"
gh repo create clinical-trial-efficacy-safety-r --public --source=. --remote=origin --push
```

If Git asks for your name/email, set them with `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"`, using your own account information.

## Running in RStudio

1. Install R and RStudio.
2. Open `ClinicalTrialAnalysis.Rproj` from the extracted folder.
3. In RStudio's console, execute `source("run_all.R")`.
4. Inspect `outputs/tables/` and `outputs/figures/`.
5. Optional: install the `rmarkdown` and `knitr` packages, then run the pipeline again to render HTML.

## Before adding the link to a resume

Run the project, read the model estimates, review the limitations, and verify that you can explain what ANCOVA, a Wilson interval and Monte Carlo error mean. The repository uses **simulated data**, not real clinical trials.
