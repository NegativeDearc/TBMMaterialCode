library(shiny)
library(RODBC)

#shinyUI(pageWithSidebar(
shinyUI(fluidPage(
  
  headerPanel (h1("当日排产备料代码汇总"),windowTitle = '备料代码汇总'),
  
  sidebarPanel(width = 2,
               helpText('本程序由',br(),
                        '技术部',br(),
                        '提供支持',
                        br(),
                        em('Tel:',br(),
                           '18260279625')
                        ),
               checkboxGroupInput("checkbox",
                                  choices = list('内面胶' = 'Innerliner Code',
                                                 '1号帘布' = '1#Ply Code',
                                                 '2号帘布' = '2#Ply Code',
                                                 '胎圈' = 'Bead code',
                                                 '胎边' = 'Sidewall code',
                                                 '1层环带' = '1# Belt code',
                                                 '2层环带' = '2# Belt code',
                                                 'SNOW' = 'SNOW code'),
                                  label = '请选择项目(可多选)'
                                  ),
               #textOutput('currentTime'),
               actionButton("action", icon = icon('refresh'),label = "刷新")
               ),
  
  mainPanel(width = 10,
    tabsetPanel(
      id = 'dataset',type = 'tabs',
      tabPanel('白班', icon = icon("list-alt"),dataTableOutput(outputId = 'table1')),
      tabPanel('夜班',icon = icon("list-alt"),dataTableOutput(outputId = 'table_night')),
      tabPanel('白班汇总', icon = icon("list-alt"),dataTableOutput(outputId = 'table')),
      tabPanel('作者',icon = icon('user'),
               h5("作者: 技术部Sheldon",br(),
                  "如遇到程序bug或者建议点击发送邮件",
                  a(href="mailto:sxchen@coopertire.com&Subject=feedback","点这里"))),
      tabPanel('更新',icon = icon('list-alt'),includeHTML('log.html'))
      ))
)
)