library(shiny)
library(mc2d)
library(ggplot2)
library(scales)
 
N <- 50000
 
shinyServer(function(input,output){

		simulate <- reactive( {
			
			TEFestimate <- data.frame(L = input$tefl,  ML = input$tefml,  H = input$tefh, CONF = input$tefconf)
			TSestimate <- data.frame(L = input$tcapl,  ML = input$tcapml,  H = input$tcaph, CONF = input$tcapconf)
			RSestimate <- data.frame(L = input$csl,  ML = input$csml,  H = input$csh, CONF = input$csconf)
			LMestimate <- data.frame(L = input$lml, ML = input$lmml, H = input$lmh, CONF = 1)

			LMsample <- function(x){
			  return(sum(rpert(x, LMestimate$L, LMestimate$ML, LMestimate$H, shape = LMestimate$CONF) ))
			}

			TEFsamples <- rpert(N, TEFestimate$L, TEFestimate$ML, TEFestimate$H, shape = TEFestimate$CONF)
			TSsamples <- rpert(N, TSestimate$L, TSestimate$ML, TSestimate$H, shape = TSestimate$CONF)
			RSsamples <- rpert(N, RSestimate$L, RSestimate$ML, RSestimate$H, shape = RSestimate$CONF)

			VULNsamples <- TSsamples > RSsamples
			LEF <- TEFsamples[VULNsamples]

			return(sapply(LEF, LMsample))
				
		})
  
    output$plot <- renderPlot({
			
			ALEsamples <- simulate()
			
			gg <- ggplot(data.frame(ALEsamples), aes(x = ALEsamples))
			gg <- gg + geom_histogram(binwidth = diff(range(ALEsamples)/50), aes(y = ..density..), color = "black", fill = "white")
			gg <- gg + geom_density(fill = "steelblue", alpha = 1/3)
			gg <- gg + scale_x_continuous(labels = comma)
			gg <- gg + theme_bw()
			
			print(gg)

    })
     
    output$detail <- renderPrint({			
			ALEsamples <- simulate()
			print(summary(ALEsamples));
    })
     
    output$detail2 <- renderPrint({
			ALEsamples <- simulate()
			VAR <- quantile(ALEsamples, probs=(0.95))
			print(paste0("Losses at 95th percentile are $", format(VAR, nsmall = 2, big.mark = ",")));
    })
     
})