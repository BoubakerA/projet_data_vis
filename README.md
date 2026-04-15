# 🌍 African Development Data Visualization

**Authors**<br>
Roger KOUAKOU<br>
Kevin N'gouan<br>
Boubaker ASAADI

---

## 📌 Overview

This project explores the evolution of key **economic** and **educational indicators** across the African continent through interactive and dynamic visualizations.

By combining modern web technologies and statistical tools, the project provides both:

* an intuitive **interactive map experience**, and
* a **data exploration dashboard** for deeper comparative analysis.

The goal is to make complex development trends **accessible, visual, and insightful**.

---

## 📊 Project Structure

```id="b3w4yt"
projet_data_vis/
│
├── vis_d3/        # Interactive D3.js visualization
└── vis_rshiny/    # R Shiny dashboard application
```

---

## 🗺️ `vis_d3` — Interactive Map (D3.js)

This module provides a **fully interactive map of Africa** built using the **D3.js** library.

### ✨ Features

* Click on any country to explore its data
* Dynamic visualizations of:

  * 📚 **Mean Years of Education** (UNDP)
  * 💰 **Gross National Income (GNI)**
  * 📈 **Human Development Index (HDI)**
* Smooth transitions and responsive interactions

### 🎯 Important ⚠️

The visualization relies on **relative paths** to load data files (GeoJSON, CSV, etc.).
Because of this, the project **must be served from the root directory** (`projet_data_vis/`), otherwise the data will not load correctly (e.g. 404 errors).

---

### ▶️ Run the visualization (correct way)

#### ✅ Recommended — VS Code Live Server (from root)

1. Open the **entire project folder** (`projet_data_vis`) in VS Code
2. Install the **Live Server** extension
3. Navigate to `vis_d3/index.html`
4. Right-click → **"Open with Live Server"**

👉 This ensures paths like `../data/...` are resolved correctly.

---

#### ❌ What NOT to do

* Do **not** open `index.html` directly in the browser
* Do **not** launch Live Server from inside `vis_d3/` only

👉 These will break file loading (especially for D3) and cause errors like:

```
Error: 404 Not Found
```

---

#### 🛠️ Alternative — Python server (from root)

```bash id="7trr08"
cd projet_data_vis
python -m http.server 8000
```

Then open:
👉 http://localhost:8000/vis_d3/

---

## 📈 `vis_rshiny` — Data Exploration App (R Shiny)

This module is a more **advanced analytical dashboard** built with **R Shiny**.

### ✨ Features

* Interactive selection of one or multiple countries
* Side-by-side **comparisons of indicators**
* Enhanced control over:

  * Time ranges
  * Indicators
  * Visualization modes

### ⚙️ Requirements

To run this application, you need:

* **R** installed
* Required R packages (typically: `shiny`, `ggplot2`, `dplyr`, etc.)

### ▶️ Run the app

```r id="p83ye9"
setwd("vis_rshiny")
shiny::runApp()
```

---

## 📦 Data Sources

The project relies on publicly available development datasets, including:

* **United Nations Development Programme (UNDP)**
* Other international economic and education datasets

---

## 🚀 Getting Started

### 1. Clone the repository

```bash id="gl9rs1"
git clone https://github.com/BoubakerA/projet_data_vis.git
cd projet_data_vis
```

### 2. Run the D3 visualization

⚠️ Make sure to start the server **from the root directory** (see above)

### 3. Run the Shiny app

```r id="jjkb6k"
shiny::runApp("vis_rshiny")
```

---

## 💡 Project Highlights

* Combines **web-based visualization (D3.js)** with **statistical computing (R Shiny)**
* Focus on **African development indicators**
* Supports both **exploration** and **comparison**
* Designed for **clarity, interactivity, and insight**

---

## 📬 Contact

For questions or collaboration, feel free to reach out via GitHub.

---

## 📝 License

This project is for academic and educational purposes.
