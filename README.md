# 🌍 African Development Data Visualization

**Authors**
Roger KOUAKOU
Kevin N'gouan
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

```
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

### 🎯 Purpose

This visualization is designed for **quick, intuitive exploration** of country-level development trends.

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

```r
shiny::runApp("vis_rshiny")
```

---

## 📦 Data Sources

The project relies on publicly available development datasets, including:

* **United Nations Development Programme (UNDP)**
* Other international economic and education datasets

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/BoubakerA/projet_data_vis.git
cd projet_data_vis
```

### 2. Run the D3 visualization

Simply open the HTML file inside `vis_d3` in your browser:

```bash
open index.html
```

### 3. Run the Shiny app

```r
setwd("vis_rshiny")
shiny::runApp()
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
