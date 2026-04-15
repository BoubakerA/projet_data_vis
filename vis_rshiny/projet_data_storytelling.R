## Installation des packages

packages = c("shiny","rnaturalearth","sf","leaflet","dplyr","plotly","readr")
install.packages(setdiff(packages, installed.packages()[,"Package"]))



## Chargement des différentes librairies
library(shiny)
library(rnaturalearth) # contour géograpgiques
library(sf) # manipulation donnes
library(leaflet) # modélisation de la carte interactive 
library(dplyr)
library(plotly)
library(tidyverse)

## la partie préparation des données: dans cette partie on importe le dataset
# on lui applique certaines transformations(filtres sur certaines colonnes)
# et on commence également à préparer les données pour la création de l'application
library(tidyverse)


# chargement des tables
#table des indicateurs
data_indicators = read_csv("../data/indicators_dataset.csv")

# table des populations
data_population_raw = read.csv("../data/population.csv",sep = ",",encoding = "latin1",check.names = FALSE)


# on procède au nettoyage colonnes vides
data_population_raw = data_population_raw %>%
  select(-which(names(.) == "" | is.na(names(.))))

# pn procède au nettoyage des codes pays
data_population_raw <- data_population_raw %>%
  mutate(`Country Code` = trimws(`Country Code`)) %>%
  filter(nchar(`Country Code`) == 3)

# On fait un pivot de la table population
data_population_long = data_population_raw %>%
  filter(`Indicator Name` == "Population, total") %>%   
  select(`Country Code`, matches("^\\d{4}$")) %>%
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "year",
    values_to = "population"
  ) %>%
  rename(countryIsoCode = `Country Code`) %>%
  mutate(
    year = as.integer(year),
    population = as.numeric(population)
  )


# On termine avec un leftjoin pour merger les deux tables
data = data_indicators %>%
  mutate(year = as.integer(year)) %>%
  left_join(data_population_long, by = c("countryIsoCode", "year"))

# On renomme une variable 
data <- data %>% rename(date = year)


pays_afrique = c(
  "Algeria","Angola","Benin","Botswana","Burkina Faso","Burundi",
  "Cabo Verde","Cameroon","Central African Republic","Chad","Comoros",
  "Congo","Cote d'Ivoire","Democratic Republic of the Congo","Djibouti",
  "Egypt","Equatorial Guinea","Eritrea","Eswatini","Ethiopia","Gabon",
  "Gambia","Ghana","Guinea","Guinea-Bissau","Kenya","Lesotho","Liberia",
  "Libya","Madagascar","Malawi","Mali","Mauritania","Mauritius","Morocco",
  "Mozambique","Namibia","Niger","Nigeria","Rwanda","Sao Tome and Principe",
  "Senegal","Seychelles","Sierra Leone","Somalia","South Africa","South Sudan",
  "Sudan","Tanzania","Togo","Tunisia","Uganda","Zambia","Zimbabwe"
)

data_afrique = data[data$country %in% pays_afrique,]
regions = data.frame(
  country = c(
    "Algeria","Morocco","Tunisia","Libya","Egypt","Sudan",
    "Nigeria","Ghana","Senegal","Mali","Niger","Benin","Togo","Guinea",
    "Liberia","Sierra Leone","Burkina Faso","Cote d'Ivoire","Mauritania",
    "Gambia","Guinea-Bissau","Cabo Verde",
    "Cameroon","Gabon","Congo","Democratic Republic of the Congo",
    "Central African Republic","Chad","Equatorial Guinea","Sao Tome and Principe","Comoros",
    "Kenya","Tanzania","Uganda","Rwanda","Burundi","Ethiopia","Somalia",
    "Djibouti","Eritrea","Madagascar","Mauritius","Seychelles","South Sudan",
    "South Africa","Botswana","Namibia","Zimbabwe","Zambia","Mozambique",
    "Angola","Malawi","Lesotho","Eswatini"
  ),
  region = c(
    "Nord","Nord","Nord","Nord","Nord","Nord",
    "Ouest","Ouest","Ouest","Ouest","Ouest","Ouest","Ouest","Ouest",
    "Ouest","Ouest","Ouest","Ouest","Ouest","Ouest","Ouest","Ouest",
    "Centre","Centre","Centre","Centre","Centre","Centre","Centre","Centre","Centre",
    "Est","Est","Est","Est","Est","Est","Est","Est","Est","Est","Est","Est","Est",
    "Austral","Austral","Austral","Austral","Austral","Austral",
    "Austral","Austral","Austral","Austral"
  )
)

data_afrique = left_join(data_afrique, regions, by = "country")

## contour des pays africains
afrique = ne_countries(continent = "Africa", returnclass = "sf")

# coloriation des différents pays

noms_pays = afrique$name
couleurs = colorRampPalette(c("#22d3ee", "#fb923c", "#34d399", "#a78bfa", "#f472b6",
                                  "#facc15", "#60a5fa", "#f87171", "#4ade80", "#e879f9"))(54)

couleurs_pays = setNames(couleurs, noms_pays)

dark_layout = function(p, xlab = "", ylab = "") {
  p %>% layout(
    xaxis = list(
      title = list(text = xlab, font = list(color = "#64748b", size = 11)),
      zeroline = FALSE, gridcolor = "#162032",
      color = "#475569", tickfont = list(color = "#64748b", size = 10),
      showgrid = TRUE
    ),
    yaxis = list(
      title = list(text = ylab, font = list(color = "#64748b", size = 11)),
      zeroline = FALSE, gridcolor = "#162032",
      color = "#475569", tickfont = list(color = "#64748b", size = 10),
      showgrid = TRUE
    ),
    plot_bgcolor  = "#0a0f1a",
    paper_bgcolor = "#0a0f1a",
    margin = list(l = 55, r = 20, t = 20, b = 50),
    hoverlabel = list(
      bgcolor = "#0d1829", bordercolor = "#1e3a5f",
      font = list(color = "#e2e8f0", size = 12)
    )
  )
  
}


add_year_vline = function(p, yr) {
  p %>% layout(shapes = list(list(
    type = "line", x0 = yr, x1 = yr, y0 = 0, y1 = 1,
    yref = "paper",
    line = list(color = "rgba(255,255,255,0.15)", width = 1.5, dash = "dot")
  )))
}


# La partie UI : la partie interface de l'application on crée les onglets et 
# leur contenu (je reconnais avoir utilisé chatgpt uniquement pour améliorer le rendu HTML-CSS)

ui = fluidPage(tags$head(tags$style(HTML("
  @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@300;400;500&display=swap');

  *, *::before, *::after { box-sizing: border-box; }

  body { background: #060a12; color: #e2e8f0; font-family: 'Inter', sans-serif; margin: 0; padding: 0; min-height: 100vh; }

  .app-header { background: #0a0f1a; border-bottom: 1px solid #1a2744; padding: 18px 32px; display: flex; align-items: center; justify-content: space-between; }
  .app-header-left h1 { margin: 0; font-family: 'Space Grotesk', sans-serif; font-size: 1.45rem; font-weight: 700; color: #f1f5f9; }
  .app-header-left p { margin: 3px 0 0; color: #475569; font-size: 0.78rem; }
  .header-badge { background: #0f1f38; border: 1px solid #1a2f50; border-radius: 20px; padding: 4px 12px; font-size: 0.72rem; font-weight: 500; color: #64748b; font-family: 'Space Grotesk', sans-serif; }
  .header-badge span { color: #22d3ee; font-weight: 600; }

  .nav-tabs { border-bottom: 1px solid #1a2744 !important; background: #0a0f1a !important; padding: 0 24px; }
  .nav-tabs > li > a { color: #475569 !important; background: transparent !important; border: none !important; border-bottom: 2px solid transparent !important; font-family: 'Space Grotesk', sans-serif !important; font-weight: 600 !important; }
  .nav-tabs > li > a:hover { color: #94a3b8 !important; }
  .nav-tabs > li.active > a { color: #22d3ee !important; border-bottom: 2px solid #22d3ee !important; background: transparent !important; }
  .tab-content { background: #060a12; }
  .tab-pane { padding: 20px 24px; }

  .well { background: #0a0f1a !important; border: 1px solid #1a2744 !important; border-radius: 12px !important; }
  .form-control, .selectize-input { background: #060a12 !important; border: 1px solid #1a2744 !important; color: #cbd5e1 !important; border-radius: 8px !important; font-size: 0.82rem !important; }
  .selectize-dropdown { background: #0a0f1a !important; border: 1px solid #1a2744 !important; border-radius: 8px !important; }
  .selectize-dropdown .option { color: #94a3b8 !important; }
  .selectize-dropdown .option:hover { background: #0f1f38 !important; color: #22d3ee !important; }
  label { color: #64748b !important; font-size: 0.8rem !important; }
  .chart-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .chart-card { background: #0a0f1a; border: 1px solid #1a2744; border-radius: 14px; padding: 16px 16px 10px; position: relative; overflow: hidden; margin-bottom: 14px; }
  .chart-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px; border-radius: 14px 14px 0 0; }
  .card-bubble::before { background: linear-gradient(90deg, #22d3ee 0%, #6366f1 100%); }
  .card-bar::before { background: linear-gradient(90deg, #fb923c 0%, #f472b6 100%); }
  .card-stream::before { background: linear-gradient(90deg, #34d399 0%, #22d3ee 100%); }
  .card-donut::before { background: linear-gradient(90deg, #a78bfa 0%, #f472b6 100%); }
  .chart-card-title { font-family: 'Space Grotesk', sans-serif; font-size: 0.75rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.9px; margin: 0 0 10px; }

  .kpi-card { background: #0a0f1a; border: 1px solid #1a2744; border-radius: 12px; padding: 18px 20px; margin-bottom: 14px; }
  .kpi-label { color: #475569; font-size: 0.68rem; font-weight: 600; text-transform: uppercase; letter-spacing: 1.2px; font-family: 'Space Grotesk', sans-serif; margin-bottom: 8px; }
  .kpi-value { font-family: 'Space Grotesk', sans-serif; font-size: 1.7rem; font-weight: 700; line-height: 1; margin-bottom: 4px; }
  .kpi-sub { color: #334155; font-size: 0.68rem; margin-top: 5px; }

  .map-container { border-radius: 12px; overflow: hidden; border: 1px solid #1a2744; }

  ::-webkit-scrollbar { width: 4px; height: 4px; }
  ::-webkit-scrollbar-track { background: #060a12; }
  ::-webkit-scrollbar-thumb { background: #1a2744; border-radius: 2px; }
"))),div(class = "app-header",
         div(class = "app-header-left",
             tags$h1("🌍 Éducation & Économie en Afrique"),
             tags$p("Données issues de World Bank pour une analyse comparative")
         ),
         div(
           div(class = "header-badge",
               HTML(paste0("<span>", length(pays_afrique), "</span> pays"))
           ),
           div(class = "header-badge",
               HTML(paste0("<span>", min(data_afrique$date), "</span> – <span>", max(data_afrique$date), "</span>"))
           )
         )
),tabsetPanel(id = "onglets",tabPanel("Carte",
                                      sidebarLayout(
                                        sidebarPanel(width = 3,
                                                     div(class = "sidebar-section",
                                                         div(class = "sidebar-label", "Navigation"),
                                                         div(style = "color:#475569; font-size:0.78rem; line-height:1.8",
                                                             tags$span(style = "color:#22d3ee; font-size:1rem", "●"),
                                                             tags$b(style = "color:#94a3b8", " Clic"),
                                                             tags$span(" sur un pays pour ouvrir sa fiche détaillée"),
                                                             tags$br(),
                                                             tags$span(style = "color:#334155; font-size:1rem", "◌"),
                                                             tags$b(style = "color:#64748b", " Survol"),
                                                             tags$span(style = "color:#334155", " pour afficher le nom")
                                                         )
                                                     )
                                        ),
                                        mainPanel(width = 9,
                                                  div(style = "padding:18px;",
                                                      div(class = "map-container",
                                                          leafletOutput("map", height = 610)
                                                      )
                                                  )
                                        )
                                      )
),
tabPanel("Graphiques",
         div(class = "controls-bar",
             div(style = "flex:0 0 150px",
                 div(class = "sidebar-label", "Année"),
                 selectInput("annee", NULL, choices = sort(unique(data_afrique$date)))
             ),
             div(style = "flex:0 0 190px",
                 div(class = "sidebar-label", "Granularité"),
                 radioButtons("niveau", NULL,
                              choices = c("Par pays", "Par région"),
                              inline = TRUE)
             ),
             div(style = "flex:1; min-width:220px",
                 div(class = "sidebar-label", "Sélection"),
                 uiOutput("selecteur")
             )
         ),
         div(class = "chart-grid",
             div(class = "chart-card card-bubble",
                 div(class = "chart-card-title", "PIB vs Scolarisation"),
                 plotlyOutput("bubble",height = "300px")
             ),
             div(class = "chart-card card-bar",
                 div(class = "chart-card-title", "Revenu national brut/hab"),
                 plotlyOutput("bar",height = "300px")
             ),
             div(class = "chart-card card-stream",
                 div(class = "chart-card-title", "Années de scolarisation"),
                 plotlyOutput("stream",height = "300px")
             ),
             div(class = "chart-card card-donut",
                 div(class = "chart-card-title", "Indice de développement humain"),
                 plotlyOutput("evolution_hdi",height = "300px")
             )
         )
),
tabPanel("Fiche du pays",
         div(style = "padding: 20px 24px;",
             div(style = "display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px;",
                 uiOutput("titre_pays"),
                 div(style = "display:flex; align-items:center; gap:10px; flex-shrink:0;",
                     div(class = "sidebar-label", style = "margin:0; line-height:2.2", "Année"),
                     div(style = "width:120px",
                         selectInput("annee_fiche", NULL, choices = sort(unique(data_afrique$date)))
                     )
                 )
             ),
             hr(style = "border: none; border-top: 1px solid #1a2744; margin: 14px 0;"),
             fluidRow(
               column(3, uiOutput("pib_habitant")),
               column(3, uiOutput("population")),
               column(3, uiOutput("scolarisation_secondaire")),
               column(3, uiOutput("pourcentage_depense"))
             ),
             br(),
             div(class = "chart-grid",
                 div(class = "chart-card card-bubble",
                     div(class = "chart-card-title", "Revenu national brut/hab"),
                     plotlyOutput("graphique_pib", height = "260px")
                 ),
                 div(class = "chart-card card-bar",
                     div(class = "chart-card-title", "Population"),
                     plotlyOutput("graphique_pop", height = "260px")
                 ),
                 div(class = "chart-card card-stream",
                     div(class = "chart-card-title", "Années de scolarisation"),
                     plotlyOutput("graphique_scolarisation", height = "260px")
                 ),
                 div(class = "chart-card card-donut",
                     div(class = "chart-card-title", "Indice de développement humain"),
                     plotlyOutput("graphique_edu", height = "260px")
                 )
             )
         )
)))

# la partie server : la partie logique pour établir les connexions avec la partie UI

server = function(input, output,session) { 
  pays_choisi = reactiveVal(NULL)
  data_pays = reactive({req(pays_choisi())
  filter(data_afrique, country == pays_choisi())})
  output$pib_habitant = renderUI({
    req(pays_choisi())
    d = data_pays() %>% filter(date == input$annee_fiche) %>% slice(1)
    if(nrow(d) == 0 || is.na(d$gnipc)) return(
      div(class = "kpi-card",
          div(class = "kpi-label", "Revenu national brut/hab"),
          div(class = "kpi-value", style = "color:#22d3ee", "—"),
          div(class = "kpi-sub", paste0("Pas de donnée en ", input$annee_fiche))
      )
    )
    div(class = "kpi-card",
        div(class = "kpi-label", "PIB par habitant"),
        div(class = "kpi-value", style = "color:#22d3ee",
            paste0(round(d$gnipc, 0), " $")),
        div(class = "kpi-sub", paste0("En ", input$annee_fiche))
    )
  })
  
  output$population = renderUI({
    req(pays_choisi())
    d = data_pays() %>% filter(date == input$annee_fiche) %>% slice(1)
    if(nrow(d) == 0 || is.na(d$population)) return(
      div(class = "kpi-card",
          div(class = "kpi-label", "Population"),
          div(class = "kpi-value", style = "color:#fb923c", "—"),
          div(class = "kpi-sub", paste0("Pas de donnée en ", input$annee_fiche))
      )
    )
    div(class = "kpi-card",
        div(class = "kpi-label", "Population"),
        div(class = "kpi-value", style = "color:#fb923c",
            paste0(round(d$population / 1e6, 1), " M")),
        div(class = "kpi-sub", paste0("En ", input$annee_fiche))
    )
  })
  
  output$scolarisation_secondaire = renderUI({
    req(pays_choisi())
    d = data_pays() %>% filter(date == input$annee_fiche)%>% slice(1)
    if(nrow(d) == 0 || is.na(d$mys)) return(
      div(class = "kpi-card",
          div(class = "kpi-label", "Scolarisation moyenne"),
          div(class = "kpi-value", style = "color:#a78bfa", "—"),
          div(class = "kpi-sub", paste0(round(d$mys, 1), " ans"))
      )
    )
    div(class = "kpi-card",
        div(class = "kpi-label", "Scolarisation moyenne"),
        div(class = "kpi-value", style = "color:#a78bfa",
            paste0(round(d$mys, 1), " ans", " %")),
        div(class = "kpi-sub", paste0("En ", input$annee_fiche))
    )
  })
  
  output$pourcentage_depense = renderUI({
    req(pays_choisi())
    d = data_pays() %>% filter(date == input$annee_fiche) %>% slice(1)
    if(nrow(d) == 0 || is.na(d$hdi)) return(
      div(class = "kpi-card",
          div(class = "kpi-label", "Indice de développement humain"),
          div(class = "kpi-value", style = "color:#34d399", "—"),
          div(class = "kpi-sub", paste0("En ", input$annee_fiche))
      )
    )
    div(class = "kpi-card",
        div(class = "kpi-label", "Indice de développement humain"),
        div(class = "kpi-value", style = "color:#34d399",
            paste0(round(d$hdi, 3))),
        div(class = "kpi-sub", paste0("En ", input$annee_fiche))
    )
  })
  output$graphique_edu = renderPlotly({
    req(pays_choisi())
    yr = as.integer(input$annee_fiche)
    d = data_pays() %>% filter(!is.na(hdi))
    if(nrow(d) == 0) return(plotly_empty() %>% layout(paper_bgcolor = "#0a0f1a", plot_bgcolor = "#0a0f1a"))
    plot_ly(d, x = ~date, y = ~hdi,
            type = "bar",
            marker = list(
              color = "rgba(52,211,153,0.65)",
              line = list(color = "#34d399", width = 1.5)
            ),
            hovertemplate = "%{x} · %{y:.2f}% du PIB<extra></extra>"
    ) %>% dark_layout(xlab = "Année", ylab = "% PIB") %>% add_year_vline(yr)
  })
  output$graphique_pib = renderPlotly({
    req(pays_choisi())
    yr = as.integer(input$annee_fiche)
    d = data_pays() %>% filter(!is.na(gnipc))
    if(nrow(d) == 0) return(plotly_empty() %>% layout(paper_bgcolor = "#0a0f1a", plot_bgcolor = "#0a0f1a"))
    plot_ly(d, x = ~date, y = ~gnipc,
            type = "scatter", mode = "lines+markers",
            line = list(color = "#22d3ee", width = 2.5),
            marker = list(color = "#22d3ee", size = 5,
                          line = list(color = "#060a12", width = 1.5)),
            fill = "tozeroy",
            fillcolor = "rgba(34,211,238,0.07)",
            hovertemplate = "%{x} · $%{y:,.0f}<extra></extra>"
    ) %>% dark_layout(xlab = "Année", ylab = "USD") %>% add_year_vline(yr)
  })
  output$graphique_pop = renderPlotly({
    req(pays_choisi())
    yr = as.integer(input$annee_fiche)
    d = data_pays() %>% filter(!is.na(population))
    if(nrow(d) == 0) return(plotly_empty() %>% layout(paper_bgcolor = "#0a0f1a", plot_bgcolor = "#0a0f1a"))
    plot_ly(d, x = ~date, y = ~population / 1e6,
            type = "scatter", mode = "lines+markers",
            fill = "tozeroy",
            fillcolor = "rgba(251,146,60,0.07)",
            line = list(color = "#fb923c", width = 2.5),
            marker = list(color = "#fb923c", size = 5,
                          line = list(color = "#060a12", width = 1.5)),
            hovertemplate = "%{x} · %{y:.2f} M hab.<extra></extra>"
    ) %>% dark_layout(xlab = "Année", ylab = "Millions") %>% add_year_vline(yr)
  })
  output$graphique_scolarisation = renderPlotly({
    req(pays_choisi())
    yr = as.integer(input$annee_fiche)
    dp = data_pays() %>% filter(!is.na(eys))
    ds = data_pays() %>% filter(!is.na(mys))
    if(nrow(dp) == 0 && nrow(ds) == 0) return(
      plotly_empty() %>% layout(paper_bgcolor = "#0a0f1a", plot_bgcolor = "#0a0f1a")
    )
    p = plot_ly()
    if(nrow(dp) > 0) {
      p = p %>% add_trace(
        data = dp, x = ~date, y = ~eys,
        type = "scatter", mode = "lines+markers", name = "Attendue (eys)",
        line = list(color = "#34d399", width = 2.5),
        marker = list(color = "#34d399", size = 5,
                      line = list(color = "#060a12", width = 1.5)),
        hovertemplate = "Primaire %{x} · %{y:.1f}%<extra></extra>"
      )
    }
    if(nrow(ds) > 0) {
      p = p %>% add_trace(
        data = ds, x = ~date, y = ~mys,
        type = "scatter", mode = "lines+markers", name = "Moyenne (mys)",
        line = list(color = "#a78bfa", width = 2.5, dash = "dot"),
        marker = list(color = "#a78bfa", size = 5,
                      line = list(color = "#060a12", width = 1.5)),
        hovertemplate = "Secondaire %{x} · %{y:.1f}%<extra></extra>"
      )
    }
    p %>% dark_layout(xlab = "Année", ylab = "%") %>% add_year_vline(yr)
  })
  output$selecteur = renderUI({
    if(input$niveau == "Par pays"){
      selectInput("entites", NULL, 
                  choices = sort(pays_afrique), 
                  multiple = TRUE,
                  selected = head(sort(pays_afrique), 6))
    } else {
      regs = sort(unique(data_afrique$region[data_afrique$region != "Autre"]))
      selectInput("entites", NULL,
                  choices = regs,
                  multiple = TRUE,
                  selected = regs)
    }
  })
  donnees_filtrees = reactive({
    req(input$entites)
    if (input$niveau == "Par pays"){
      data_afrique %>% filter(date == input$annee, country %in% input$entites)
    } else {
      data_afrique %>% 
        filter(date == input$annee, region %in% input$entites) %>%
        group_by(region) %>%
        summarise(
          gnipc = mean(gnipc, na.rm = TRUE),
          mys = mean(mys, na.rm = TRUE),
          eys = mean(eys, na.rm = TRUE),
          hdi = mean(hdi, na.rm = TRUE),
          population = sum(population, na.rm = TRUE),
          .groups = "drop"
        )
    }
  })
  output$bubble = renderPlotly({
    req(input$annee, input$entites)
    d = donnees_filtrees()
    col = if(input$niveau == "Par pays") "country" else "region"
    
    entites = unique(d[[col]])
    n = length(entites)
    
    pal = colorRampPalette(c(
      "#22d3ee","#fb923c","#34d399","#a78bfa","#f472b6",
      "#facc15","#60a5fa","#f87171","#4ade80","#e879f9"
    ))(n)
    pal = setNames(pal, entites)
    
    p = plot_ly()
    for (ent in entites) {
      dr = d %>% filter(.data[[col]] == ent)
      p = add_trace(p,
                    data = dr, type = "scatter", mode = "markers",
                    x = ~gnipc, y = ~mys,
                    size = ~population, name = ent,
                    marker = list(color = pal[ent], opacity = 0.85,
                                  sizemin = 14,
                                  line = list(width = 1.5, color = "rgba(255,255,255,0.2)"))
      )
    }
    p %>% dark_layout(xlab = "Revenu national brut/hab", ylab = "Scolarisation moyenne (ans)")%>% layout(showlegend = TRUE)
  })
  output$stream = renderPlotly({
    req(input$entites)
    d = data_afrique %>%
      group_by(date, region) %>%
      summarise(val = mean(eys, na.rm = TRUE), .groups = "drop") %>%
      filter(!is.na(val)) %>%
      rename(label = region)
    
    plot_ly(d, x = ~date, y = ~val, color = ~label,
            type = "scatter", mode = "none", stackgroup = "one") %>%
      dark_layout(xlab = "Année", ylab = "Années de scolarisation attendues")
  })
  output$evolution_hdi = renderPlotly({
    req(input$annee, input$entites)
    if(input$niveau == "Par pays"){
      d = data_afrique %>% filter(country %in% input$entites) %>%
        group_by(date, country) %>%
        summarise(val = mean(hdi, na.rm = TRUE), .groups = "drop") %>%
        rename(label = country)
    } else {
      d = data_afrique %>% filter(region %in% input$entites) %>%
        group_by(date, region) %>%
        summarise(val = mean(hdi, na.rm = TRUE), .groups = "drop") %>%
        rename(label = region)
    }
    plot_ly(d, x = ~date, y = ~val, color = ~label,
            type = "scatter", mode = "lines+markers",
            hovertemplate = "%{x} · %{y:.3f}<extra></extra>"
    ) %>% dark_layout(xlab = "Année", ylab = "HDI")
  })
  output$bar = renderPlotly({
    req(input$annee, input$entites)
    d = donnees_filtrees() %>% arrange(gnipc)
    col = if(input$niveau == "Par pays") "country" else "region"
    req(nrow(d) > 0)
    
    vivid_pal = colorRampPalette(c(
      "#f472b6","#fb923c","#facc15","#34d399",
      "#22d3ee","#60a5fa","#a78bfa","#e879f9"
    ))(nrow(d))
    
    plot_ly(d,
            x = ~gnipc,
            y = ~reorder(.data[[col]], gnipc),
            type = "bar", orientation = "h",
            marker = list(color = vivid_pal,
                          line = list(color = "rgba(255,255,255,0.05)", width = 0.5)),
            text = ~paste0("$", format(round(gnipc, 0), big.mark = " ")),
            textposition = "outside",
            textfont = list(color = "#475569", size = 10,
                            family = "Space Grotesk, sans-serif"),
            hovertemplate = "<b>%{y}</b><br>$%{x:,.0f}<extra></extra>"
    ) %>%
      dark_layout(xlab = "Revenu national brut/hab") %>%
      layout(showlegend = FALSE,
             yaxis = list(tickfont = list(color = "#94a3b8", size = 10),
                          automargin = TRUE))
  })
  output$titre_pays = renderUI({
    country = pays_choisi()
    if (is.null(country)) {
      return(div(style = "color:#334155; font-size:0.9rem; font-family:'Space Grotesk',sans-serif;",
                 "🗺️ Cliquez sur un pays dans la carte"))
    }
    reg = unique(data_pays()$region)[1]
    couleurs_region = c("Nord"="#22d3ee","Ouest"="#fb923c","Centre"="#34d399",
                        "Est"="#a78bfa","Austral"="#f472b6")
    color = couleurs_region[reg]
    if (is.na(color)) color = "#64748b"
    div(
      style = "display:flex; align-items:center; gap:8px;",
      tags$h3(style = "color:#f1f5f9; font-family:'Space Grotesk',sans-serif; margin:0;", country),
      span(style = paste0("background:", color, "22; color:", color,
                          "; border:1px solid ", color, "44;",
                          "border-radius:20px; padding:4px 14px;",
                          "font-size:0.72rem; font-weight:600;",
                          "font-family:'Space Grotesk',sans-serif;"), reg)
    )
  })
  output$map = renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.DarkMatter) %>%
      setView(lng = 20, lat = 5, zoom = 3)
  })
  
  observe({
    df_lab = afrique %>% st_drop_geometry()
    fill_colors = ifelse(df_lab$name %in% names(couleurs_pays),
                         couleurs_pays[df_lab$name], "#1a2744")
    
    labels_simple = lapply(seq_len(nrow(df_lab)), function(i) {
      r = df_lab[i, ]
      htmltools::HTML(paste0(
        "<div style='font-family:Space Grotesk,sans-serif;background:#0a0f1a;",
        "border:1px solid #1a2744;border-radius:8px;padding:7px 12px;",
        "color:#e2e8f0;font-size:12px;font-weight:600'>",
        r$name,
        "<br><span style='color:#334155;font-size:10px;font-weight:400'>Cliquer pour la fiche</span>",
        "</div>"
      ))
    })
    
    leafletProxy("map") %>%
      clearShapes() %>%
      addPolygons(
        data = afrique,
        layerId = ~name,
        fillColor = fill_colors,
        color = "#060a12",
        weight = 0.6,
        fillOpacity = 0.82,
        highlightOptions = highlightOptions(
          weight = 2, color = "#22d3ee",
          fillOpacity = 1, bringToFront = TRUE
        ),
        label = labels_simple,
        labelOptions = labelOptions(
          style = list("background" = "transparent", "border" = "none",
                       "box-shadow" = "none", "padding" = "0"),
          direction = "auto"
        )
      )
  })

  observeEvent(input$map_shape_click, {
    clic_pays = input$map_shape_click$id
    if(!is.null(clic_pays) && clic_pays %in% pays_afrique) {
      pays_choisi(clic_pays)
      updateTabsetPanel(session, "onglets", selected = "Fiche du pays")
    }
  })
}

# Lancemet de l'application
shinyApp(ui, server)

