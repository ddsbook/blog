library(shiny)
library(plyr)
library(mc2d)
library(ggplot2)
library(scales)

shinyServer(function(input,output){
  
  values <- reactiveValues() 
  
  observe({
    
    if (input$runmodel != 0) {
      
      isolate({
        
        TEFestimate <- data.frame(L = input$tefl,  ML = input$tefml,  H = input$tefh, CONF = input$tefconf)
        TSestimate <- data.frame(L = input$tcapl,  ML = input$tcapml,  H = input$tcaph, CONF = input$tcapconf)
        RSestimate <- data.frame(L = input$csl,  ML = input$csml,  H = input$csh, CONF = input$csconf)
        LMestimate <- data.frame(L = input$lml, ML = input$lmml, H = input$lmh, CONF = input$lmconf)
        
        LMsample <- function(x){
          return(sum(rpert(ifelse(x>=1,x,1), input$lml, input$lmml, input$lmh, shape = input$lmconf)))
        }
        
        TEFsamples <- rpert(input$N, TEFestimate$L, TEFestimate$ML, TEFestimate$H, shape = TEFestimate$CONF)
        TSsamples <- rpert(input$N, TSestimate$L, TSestimate$ML, TSestimate$H, shape = TSestimate$CONF)
        RSsamples <- rpert(input$N, RSestimate$L, RSestimate$ML, RSestimate$H, shape = RSestimate$CONF)
        
        VULNsamples <- TSsamples > RSsamples
        LEF <- TEFsamples[VULNsamples]
        
        values$LEF = LEF
        
        # values$ALEsamples <- sapply(LEF, LMsample)
        values$ALEsamples <- sapply(LEF, function(x) { sum(rpert(ifelse(x>=1,x,1), input$lml, input$lmml, input$lmh, shape = input$lmconf)) })
        values$VAR <- quantile(values$ALEsamples, probs=(0.95))
        
      })
      
    }
    
  })
  
  output$detail <- renderPrint({
    if (input$runmodel != 0) {
      print(summary(values$ALEsamples));
    }
  })
  
  output$detail2 <- renderPrint({
    if (input$runmodel != 0) {
      print(paste0("Losses at 95th percentile are $", format(values$VAR, nsmall = 2, big.mark = ",")));
    }
  })
  
  
  output$plot <- renderPlot({
    
    if (input$runmodel != 0) {
      
      ALEsamples <- values$ALEsamples 
      
      gg <- ggplot(data.frame(ALEsamples), aes(x = ALEsamples))
      gg <- gg + geom_histogram(binwidth = diff(range(ALEsamples)/50), aes(y = ..density..), color = "black", fill = "white")
      gg <- gg + labs(x="Loss Magnitude", y="Loss Frequency Density")
      gg <- gg + geom_density(fill = "steelblue", alpha = 1/3)
      gg <- gg + scale_x_continuous(labels = comma)
      gg <- gg + scale_y_continuous(labels = comma)
      gg <- gg + theme_bw()
      
      print(gg)
      
    }	
    
  })
  
  output$plot1 <- renderPlot({
    
    if (input$runmodel != 0) {
      
      ALEsamples <- values$ALEsamples 
      
      abc <- adply(matrix(ALEsamples, ncol = 1), 2, quantile, c(0, .25, .5, .75, 1))
      
      gg <- ggplot(abc, aes(x = X1, ymin = `0%`, lower = `25%`, middle = `50%`, upper = `75%`, ymax = `100%`))
      gg <- gg + geom_boxplot(stat = "identity", fill="steelblue")
      gg <- gg + scale_y_continuous(labels = comma)
      gg <- gg + labs(x="", y="Loss Magnitude")
      gg <- gg + coord_flip()
      gg <- gg + theme_bw()
      gg <- gg + theme(legend.position="none")
      gg <- gg + theme(panel.grid=element_blank())
      gg <- gg + theme(panel.border=element_blank())
      gg <- gg + theme(axis.ticks.y=element_blank())
      gg <- gg + theme(axis.text.y=element_blank())
      
      print(gg)
      
    }
    
  })
  
  output$plot2 <- renderPlot({
    
    if (input$runmodel != 0) {
      
      ALEsamples <- values$ALEsamples 
      LEF <- values$LEF
      
      loss <- data.frame(LEF, ALEsamples)
      gg <- ggplot(loss)
      gg <- gg + geom_point(aes(x=LEF, y=ALEsamples), color="steelblue", alpha=1/5)
      gg <- gg + labs(x="Loss Event Frequency (# times/year)", y="Loss Magnitude")
      gg <- gg + scale_x_log10(breaks=c(0.01, 0.10, 1.00, 10.00, 100.00, 1000.00, 10000), labels=comma, limits=c(0.01, 10000))
      gg <- gg + scale_y_log10(breaks=c(100,1000,10000,100000,1000000,10000000,100000000), labels = comma, limits=c(100, 100000000))
      gg <- gg + theme_bw()
      
      print(gg)
      
    }
    
  })
  
})