#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyBS)
library(rsconnect)

model <- function(age, gout_ipv, reliever, ckd, htx){
    y <- -3.99406+1.39497*gout_ipv-0.61579*reliever+1.21515*htx+0.77078*ckd+0.04405*age
    return(1/(1 + exp(-y)))
}

# Define UI for application
ui <- fluidPage(
    
    tags$title(HTML("Gout Admission Risk Estimator")),
    fluidRow(
        column(2),
        column(8,
               h2("Gout Admission Risk Estimator",
                             style='padding-bottom: 2px;margin-bottom: 2px')
               ,
               p("A tool to estimate the likelihood of admission upon A&E visit for gout patients",style = "color:grey"),
               hr(),
               fluidRow(
                   column(4,
                          numericInput("age",
                                       "Age",
                                       40,
                                       min = 1,
                                       max = 99,
                                       step = 1),
                          # bsTooltip(id = "gout_ipv", title = "", 
                          #           placement = "right", trigger = "hover"),
                          selectInput("gout_ipv", "Hospitalized for gout within last year",c("No","Yes")),
                          selectInput("reliever", "Received gout flare medications within last year",c("No","Yes")),
                          selectInput("ckd", "Chronic Kidney Disease",c("No","Yes")),
                          selectInput("htx", "Hypertension",c("No","Yes")),
                          verbatimTextOutput('score')),
                   column(8,
                          p('To facilitate the
                            development and early institution of targeted
                            interventions to reduce the frequency of gout-related
                            admissions, and potentially allow for the improvement
                            of the care of these complex multimorbid patients, we
                            examined the potential factors that predict the gout-related
                            admissions and come up with a risk predicition model with
                            5 easy predictors.'),
                          img(src='ROC.png', align = "right", width="100%"),
                          p("For more details, read our paper from: xxxxx")
                          )),
               hr(),
               HTML("<p>© <a href='https://www.mornin-feng.com'>Mornin Lab</a> 2020</p>")
               ),
        column(2)
    ),
    
)

server <- function(input, output) {

    output$score <- renderText({
        age    <- as.numeric(input$age)
        gout_ipv <- as.numeric(if(input$gout_ipv == "No") 0 else 1)
        reliever <- as.numeric(if(input$reliever == "No") 0 else 1)
        ckd <- as.numeric(if(input$ckd == "No") 0 else 1)
        htx <- as.numeric(if(input$htx == "No") 0 else 1)
        paste("Likelihood of admission:", toString(round(model(age, gout_ipv, reliever, ckd, htx),2) * 100), "%")
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
# run deployApp() from the console
