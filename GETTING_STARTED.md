# GETTING STARTED: Reproducible Workflow for Judbury Camera Trap Analysis

## Purpose

This project uses a reproducible, version-locked R environment to ensure analyses can be reliably run by any collaborator, now or in the future.
You don’t need to be an R power user—just follow these steps to get started.

---

## Quickstart

### 1. **Clone or Download the Repository**

If you have Git:

```sh
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>
```

Or download and unzip from GitHub.

---

### 2. **Install R (if needed)**

* [Download R for Windows, Mac, or Linux](https://cran.r-project.org/)
* **Recommended:** [RStudio](https://posit.co/download/rstudio-desktop/) for a friendly interface.

---

### 3. **Bootstrap the Project Environment**

#### **Windows PowerShell:**

```powershell
Rscript .\bootstrap_env.R
```

#### **Mac/Linux Terminal:**

```sh
Rscript ./bootstrap_env.R
```

* This restores the project’s locked `renv` environment.
* On first run, this may take a few minutes (packages may need to compile).

---

### 4. **Install Quarto + PDF tools (for reports)**

* Install Quarto: <https://quarto.org/docs/get-started/>
* For PDF reports, install TinyTeX or another LaTeX distribution.

---

### 5. **Open the Project in RStudio**

* Open the project folder.
* RStudio will detect and activate the project environment automatically via `.Rprofile`.

---

### 6. **Run the Analysis Pipeline**

In your RStudio Console or R terminal:

```r
targets::tar_make()
```

* The first run will build all steps of the analysis.
* If you see `"pipeline is up to date"`, everything is ready.

---

## What’s Happening Under the Hood?

* **`bootstrap_env.R`**: Activates the project and runs `renv::restore(prompt = FALSE)`.
* **`renv.lock`**: Records the exact versions of all R packages needed.
* **`_targets.R`**: Controls automated, reproducible analysis pipelines.
* Custom code lives in `R/`.

---

## Restoring the Environment Later

If you (or a collaborator) ever want to sync the project library to the locked versions, just run:

```r
renv::restore(prompt = FALSE)
```

---

## Troubleshooting

* **“Rscript not found”**: [Add R to your PATH](https://cran.r-project.org/bin/windows/base/rw-FAQ.html#R-on-Windows).
* **Package install errors on Windows**: You may need [Rtools](https://cran.r-project.org/bin/windows/Rtools/).
* **Other issues**: Raise an [Issue on GitHub](https://github.com/<your-org>/<your-repo>/issues) or contact the maintainer.

---

## Further Reading

* [`renv` documentation](https://rstudio.github.io/renv/)
* [`targets` documentation](https://docs.ropensci.org/targets/)
* [Reproducible research with R](https://www.nature.com/articles/s41559-019-0970-3)
* [R for Ecologists (DataCamp)](https://www.datacamp.com/tutorial/r-for-ecologists)

---

**Feedback or questions?**
Open an issue or contact [Barry Brook](mailto:barry.brook@utas.edu.au).

---

*This document is designed for newcomers to reproducible R workflows. Please suggest improvements as you encounter friction points!*
