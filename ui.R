if(!require('shiny')) {
  install.packages('shiny')
}
if (!require('RODBC')) {
  install.packages('RODBC')
}
if (!require('networkD3')) {
  install.packages('networkD3')
}

#shinyUI(pageWithSidebar(
shinyUI(fluidPage(
  headerPanel (h1("当日排产备料代码汇总"),windowTitle = '备料代码汇总'),
  
  sidebarPanel(
    width = 2,
    helpText(
      '本程序由',br(),
      '技术部',br(),
      '提供支持',
      br(),
      em('Tel:',br(),
         '18260279625')
    ),
    checkboxGroupInput(
      "checkbox",
      choices = list(
        '内面胶' = 'Innerliner Code',
        '1号帘布' = '1#Ply Code',
        '2号帘布' = '2#Ply Code',
        '胎圈' = 'Bead code',
        '胎边' = 'Sidewall code',
        '1层环带' = '1# Belt code',
        '2层环带' = '2# Belt code',
        'SNOW' = 'SNOW code'
      ),
      label = '请选择项目(可多选)'
    ),
    downloadButton('download',label = '下载')
  ),
  
  mainPanel(
    width = 10,
    tabsetPanel(
      id = 'dataset',type = 'tabs',
      tabPanel(
        '白班', icon = icon("list-alt"),value = 'day',dataTableOutput(outputId = 'table1')
      ),
      tabPanel(
        '夜班',icon = icon("list-alt"),value = 'night',dataTableOutput(outputId = 'table_night')
      ),
      tabPanel('白班汇总', icon = icon("list-alt"),dataTableOutput(outputId = 'table')),
      tabPanel(
        'NetworkD3',icon = icon('file-image-o'),simpleNetworkOutput(outputId = 'network')
      ),
      tabPanel(
        '作者',icon = icon('user'),
        h5(
          "作者: 技术部Sheldon",br(),
          "如遇到程序bug或者建议点击发送邮件",
          a(href = "mailto:sxchen@coopertire.com&Subject=feedback","点这里")
        )
      )
    )
  )
)
)