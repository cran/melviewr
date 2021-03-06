

#==============================================================================#
# Function for creating color picker modal
colorPicker <- function() {

    w <- gwindow("Color Picker")
    mainGroup <- ggroup(horizontal = FALSE, container = w, expand = TRUE)
    topGroup <- ggroup(horizontal = TRUE, container = mainGroup, expand = TRUE)
    valueFrame <- gframe(container = topGroup)
    hueFrame <- gframe(container = topGroup, expand = TRUE)
    valuePlot <- ggraphics(height = 300, width = 300, container = valueFrame)
    huePlot <- ggraphics(height = 300, width = 10, container = hueFrame)
    selectionGroup <- ggroup(horizontal = TRUE, container = mainGroup)
    selectionLabel <- glabel("Selection:", container = selectionGroup)
    selectionPlot <- ggraphics(height = 10, width = 50, container = selectionGroup)
    buttonGroup <- ggroup(horizontal = TRUE, container = mainGroup)
    selectButton <- gbutton("OK", container = buttonGroup)
    cancelButton <- gbutton("Cancel", container = buttonGroup)
    rainbowmatrix <- matrix(seq(0, 1, length.out = 1000), nrow = 1)
    rainbowcolors <- grDevices::rainbow(1000, start = 0, end = 1)
    hueColorMatrix <- NULL
    hueMatrix <- NULL
    selection <- NULL

    visible(huePlot) <- TRUE
    graphics::par(oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0))
    graphics::image(rainbowmatrix, col = rainbowcolors, axes = F)
    hueSelector <- function(h, ...) {
        x <- h$x
        y <- h$y
        if (x < -1 || x > 1 || y < 0 || y > 1)
            return()
        index <- round(y * ncol(rainbowmatrix))
        chosenHue <- rainbowcolors[index]
        updateValuePlot(chosenHue)
    }
    addHandlerClicked(huePlot, hueSelector)
    updateValuePlot <- function(hue) {
        visible(valuePlot) <- TRUE
        graphics::par(oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0))
        hueRampPalette <- grDevices::colorRampPalette(c("white", hue, "black"))
        hueColorMatrix <<- hueRampPalette(1000)
        hueMatrix <<- matrix(seq(0, 1, length.out = 1000), nrow = 1)
        graphics::image(hueMatrix, col = hueColorMatrix, axes = F)
    }

    updateValuePlot(rainbowcolors[1])
    valueSelector <- function(h, ...) {
        x <- h$x
        y <- h$y
        if (x < -1 || x > 1 || y < 0 || y > 1)
            return()
        index <- round(y * ncol(hueMatrix))
        chosenValue <- hueColorMatrix[index]
        updateSelectionPlot(chosenValue)
        selection <<- chosenValue
    }
    addHandlerClicked(valuePlot, valueSelector)

    updateSelectionPlot <- function(value) {
        visible(selectionPlot) <- TRUE
        graphics::par(oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0))
        graphics::image(matrix(1), col = value, axes = FALSE)
    }

    finalSelection <- NULL

    makeSelection <- function(h, ...) {
        if (!is.null(selection)) {
            finalSelection <<- selection
        } else {
            finalSelection <<- NA
        }
        dispose(w)
    }
    addHandlerClicked(selectButton, makeSelection)

    cancelSelection <- function(h, ...) {
        finalSelection <<- NA
        dispose(w)
    }
    addHandlerClicked(cancelButton, cancelSelection)
    addHandlerUnrealize(w, cancelSelection)

    while (is.null(finalSelection)) {
        Sys.sleep(0.5)
    }
    return(finalSelection)
} # End colorPicker function definition
#==============================================================================#



#==============================================================================#
# Functions for testing validity of inputs

testICADIR <- function(ICADIR) {
  if (!dir.exists(ICADIR)) stop(paste('ICA directory does not exist:', ICADIR), call. = FALSE)
  if (!file.exists(paste0(ICADIR, '/melodic_IC.nii.gz')) && !file.exists(paste0(ICADIR, '/melodic_IC.nii')))
    stop(paste('No "melodic_IC" file found in ICA directory:', ICADIR), call. = FALSE)
}

testStandardFile <- function(standard_file) {
  if (!file.exists(standard_file)) stop(paste('The standard file specified does not exist:', standard_file))
}

testMotionFile <- function(motion_file) {
  if (!file.exists(motion_file)) stop(paste('The motion file specified does not exist:', motion_file))
}

# END Functions for testing validity of inputs
#==============================================================================#



#==============================================================================#
# Function to initialize viewr object

#' A Reference Class that represents the melviewr GUI and all its data
#'
#' @field win An instance of a gwidgets gwindow.
#' @field widgets A list to hold gwidgets widgets.
#' @field settings A list to hold graphics settings and defaults.
#' @field status A list to hold state-related status information.
#' @field data A list to hold all necessary data the GUI uses.
#' @noRd
Viewr <- setRefClass("Viewr", fields = list(
    win = "gWindow",
    widgets = "list",
    settings = "list",
    status = "list",
    data = "list"
  ), methods = list(
    createGUI = function() {
      "Creates and populates the GUI"

      # main window
      win <<- gwindow("Melodic Results Viewer")
      size(win) <<- c(1600, 1000)
      Sys.sleep(0.1)
      size(win) <<- c(500, 500)

      # status bar
      widgets$statusBar <<- gstatusbar("", container = win)

      # big group
      widgets$bigGroup <<- glayout(horizontal = FALSE, container = win, expand = TRUE)

      # group for the top portion (main axial viewer and component table)
      widgets$topGroup <<- glayout(horizontal = TRUE, container = widgets$bigGroup, expand = TRUE)
      widgets$bigGroup[1, 1, expand = TRUE] <<- widgets$topGroup

      # group for the bottom portion
      widgets$bottomGroup <<- ggroup(horizontal = TRUE, container = widgets$bigGroup, expand = TRUE)
      widgets$bigGroup[2, 1, expand = TRUE] <<- widgets$bottomGroup

      # group for control buttons
      widgets$buttonGroup <<- ggroup(horizontal = TRUE, container = widgets$bigGroup)
      widgets$bigGroup[3, 1] <<- widgets$buttonGroup

      # Populate Top Group
      widgets$MainPlotGroup <<- ggroup(horizontal = FALSE, container = widgets$topGroup, expand = TRUE)
      widgets$topGroup[1, 1:5, expand = TRUE] <<- widgets$MainPlotGroup
      widgets$MainPlotLabel <<- glabel("", container = widgets$MainPlotGroup)
      widgets$MainPlotFrame <<- gframe("", container = widgets$MainPlotGroup, expand = TRUE)
      widgets$MainPlot <<- ggraphics(width = 150, height = 300, container = widgets$MainPlotFrame, handler = .self$updatePlots,
                                     expand = TRUE)
      widgets$CompTable <<- gtable(data$COMPTABLE, container = widgets$topGroup, expand = TRUE)
      widgets$topGroup[1, 6, expand = TRUE] <<- widgets$CompTable

      # Populate Bottom Group
      widgets$PlotGroup <<- ggroup(horizontal = FALSE, container = widgets$bottomGroup, expand = TRUE)
      widgets$TimeFrame <<- gframe("Timecourse", container = widgets$PlotGroup, expand = TRUE)
      widgets$TimePlot <<- ggraphics(width = 150, height = 50, container = widgets$TimeFrame, expand = TRUE)
      widgets$FreqFrame <<- gframe("Powerspectrum of Timecourse", container = widgets$PlotGroup, expand = TRUE)
      widgets$FreqPlot <<- ggraphics(width = 150, height = 50, container = widgets$FreqFrame, expand = TRUE)
      widgets$GraphicsFrame <<- gframe("Graphics Options", container = widgets$bottomGroup)
      widgets$ClassificationFrame <<- gframe("Classification", container = widgets$bottomGroup)
      Sys.sleep(0.5)

      # Populate Graphics Frame
      widgets$GraphicsTable <<- glayout(container = widgets$GraphicsFrame)
      widgets$GraphicsTable[1, 1] <<- glabel("# Columns:", container = widgets$GraphicsTable)
      widgets$ColNumInput <<- gcombobox(1:100, selected = settings$graphics$numBrainCols, container = widgets$GraphicsTable,
                                        handler = .self$updatePlots)
      widgets$GraphicsTable[1, 2] <<- widgets$ColNumInput
      widgets$GraphicsTable[2, 1] <<- glabel("Skip Slices:", container = widgets$GraphicsTable)
      widgets$SkipInput <<- gcombobox(1:100, selected = settings$graphics$skipSlices, container = widgets$GraphicsTable,
                                      handler = .self$updatePlots)
      widgets$GraphicsTable[2, 2] <<- widgets$SkipInput
      widgets$GraphicsTable[3, 1] <<- glabel("Threshold: +/-", container = widgets$GraphicsTable)
      widgets$ThresholdInput <<- gedit("2.3", container = widgets$GraphicsTable, handler = .self$updatePlots)
      widgets$GraphicsTable[3, 2] <<- widgets$ThresholdInput
      widgets$GraphicsTable[4, 1] <<- glabel("Brain darkness:", container = widgets$GraphicsTable)
      widgets$BrainColSlider <<- gspinbutton(from = 0, to = 1, by = 0.2, value = settings$graphics$brainColValue,
                                             container = widgets$GraphicsTable, handler = .self$updatePlots)
      widgets$GraphicsTable[4, 2] <<- widgets$BrainColSlider
      widgets$GraphicsTable[5, 1] <<- glabel("Background darkness:", container = widgets$GraphicsTable)
      widgets$BackgroundSlider <<- gspinbutton(from = 0, to = 100, by = 20, value = settings$graphics$brainBackgroundValue,
                                               container = widgets$GraphicsTable, handler = .self$updatePlots)
      widgets$GraphicsTable[5, 2] <<- widgets$BackgroundSlider
      widgets$ShowMotionCheckbox <<- gcheckbox("Show Motion Plot", checked = !is.null(data$MOTIONFILE),
                                               container = widgets$GraphicsTable, handler = function(h, ...) {
                                                 .self$drawTimeFigures(svalue(widgets$CompTable))
                                               })
      if (is.null(data$MOTIONFILE)) {
        enabled(widgets$ShowMotionCheckbox) <<- FALSE
      }
      widgets$GraphicsTable[6, 1] <<- widgets$ShowMotionCheckbox

      widgets$TimeOptionsToggle <<- gexpandgroup("Timecourse Plot Options", horizontal = FALSE, container = widgets$GraphicsTable)
      widgets$GraphicsTable[7, 1:2] <<- widgets$TimeOptionsToggle
      widgets$timeCourseLineColorButton <<- gbutton("Set Line Color", container = widgets$TimeOptionsToggle, action = "TimePlotLineColor", handler = .self$colorPickerHandler)
      widgets$timeCourseBgColorButton <<- gbutton("Set Background Color", container = widgets$TimeOptionsToggle, action = "TimePlotBackgroundColor",
                                                  handler = .self$colorPickerHandler)
      widgets$timeCourseLabelsColorButton <<- gbutton("Set Labels Color", container = widgets$TimeOptionsToggle, action = "TimePlotLabelColor", handler = .self$colorPickerHandler)
      widgets$timeCourseLineWidthGroup <<- ggroup(horizontal = TRUE, container = widgets$TimeOptionsToggle)
      widgets$timeCourseLineWidthLabel <<- glabel("Set Line Width:", container = widgets$timeCourseLineWidthGroup)
      widgets$timeCourseLineWidthChooser <<- gspinbutton(from = 0.1, to = 3, by = 0.1, value = settings$graphics$TimePlotLineWidth, container = widgets$timeCourseLineWidthGroup,
                                                         handler = function(h, ...) {
                                                           settings$graphics$TimePlotLineWidth <<- svalue(widgets$timeCourseLineWidthChooser)
                                                           .self$drawTimeFigures(svalue(widgets$CompTable))
                                                         })

      widgets$FreqOptionsToggle <<- gexpandgroup("Powerspectrum Plot Options", horizontal = FALSE, container = widgets$GraphicsTable)
      widgets$GraphicsTable[8, 1:2] <<- widgets$FreqOptionsToggle
      widgets$freqLineColorButton <<- gbutton("Set Line Color", container = widgets$FreqOptionsToggle, action = "FreqPlotLineColor", handler = .self$colorPickerHandler)
      widgets$freqBgColorButton <<- gbutton("Set Background Color", container = widgets$FreqOptionsToggle, action = "FreqPlotBackgroundColor", handler = .self$colorPickerHandler)
      widgets$freqLabelsColorButton <<- gbutton("Set Labels Color", container = widgets$FreqOptionsToggle, action = "FreqPlotLabelColor", handler = .self$colorPickerHandler)
      widgets$freqLineWidthGroup <<- ggroup(horizontal = TRUE, container = widgets$FreqOptionsToggle)
      widgets$freqLineWidthLabel <<- glabel("Set Line Width:", container = widgets$freqLineWidthGroup)
      widgets$freqLineWidthChooser <<- gspinbutton(from = 0.1, to = 3, by = 0.1, value = settings$graphics$FreqPlotLineWidth, container = widgets$freqLineWidthGroup,
                                                   handler = function(h, ...) {
                                                     settings$graphics$FreqPlotLineWidth <<- svalue(widgets$freqLineWidthChooser)
                                                     .self$drawTimeFigures(svalue(widgets$CompTable))
                                                   })

      widgets$MotionOptionsToggle <<- gexpandgroup("Motion Plot Options", horizontal = FALSE, container = widgets$GraphicsTable)
      widgets$GraphicsTable[9, 1:2] <<- widgets$MotionOptionsToggle
      widgets$motionLineColorButton <<- gbutton("Set Line Color", container = widgets$MotionOptionsToggle, action = "MotionPlotLineColor", handler = .self$colorPickerHandler)
      widgets$motionLineAlphaGroup <<- ggroup(horizontal = T, container = widgets$MotionOptionsToggle)
      widgets$motionLineAlphaLabel <<- glabel("Line Opacity:", container = widgets$motionLineAlphaGroup)
      widgets$motionLineAlphaChooser <<- gspinbutton(from = 0, to = 99, by = 10, value = settings$graphics$MotionPlotLineAlpha, container = widgets$motionLineAlphaGroup,
                                                     handler = function(h, ...) {
                                                       settings$graphics$MotionPlotLineAlpha <<- svalue(widgets$motionLineAlphaChooser)
                                                       .self$drawTimeFigures(svalue(widgets$CompTable))
                                                     })
      if (is.null(data$MOTIONFILE))
        enabled(widgets$MotionOptionsToggle) <<- FALSE

      widgets$GraphicsTable[10, 1:2] <<- gbutton("Save Graphics Settings", container = widgets$GraphicsTable, handler = .self$saveGraphicsSettings)
      widgets$GraphicsTable[11, 1:2] <<- gbutton("Restore Default Settings", container = widgets$GraphicsTable, handler = .self$restoreDefaultGraphicsSettings)

      # Populate Classification Frame
      classificationOptions <- c("Signal", "Unknown", "Unclassified Noise", "Movement", "Cardiac", "White matter", "Non-brain", "MRI",
                                 "Susceptibility-motion", "Sagittal sinus", "Respiratory")
      widgets$ClassificationRadio <<- gradio(classificationOptions, horizontal = FALSE, container = widgets$ClassificationFrame, handler = .self$updateClassLabel)


      # Populate button group
      widgets$ButtonFrame <<- gframe("", horizontal = TRUE, container = widgets$buttonGroup)
      widgets$LoadButton <<- gbutton("Load ICA directory", container = widgets$ButtonFrame, handler = .self$getICADIR)
      widgets$LoadStandardButton <<- gbutton("Load Standard File", container = widgets$ButtonFrame, handler = function(h, ...) {
        data$STANDARDFILE <<- gfile(type = "open",
                                    initialfilename = paste0(Sys.getenv('FSLDIR'), '/data/standard/MNI152_T1_2mm_brain.nii.gz'))
        loadStandard(data$STANDARDFILE)
      })
      widgets$LoadMotionButton <<- gbutton("Load Motion File", container = widgets$ButtonFrame, handler = .self$getMotionFile)
      widgets$SaveButton <<- gbutton("Save Classification File", container = widgets$ButtonFrame, handler = .self$saveClassificationFile)
      widgets$ExitButton <<- gbutton("Exit", container = widgets$ButtonFrame, handler = function(h, ...){
        status$exit <<- TRUE
        dispose(win)
      })

    },
    drawFrequency =  function(fdat, TR, nTRs) {
      visible(widgets$FreqPlot) <<- TRUE
      maximum <- 1/(TR * nTRs)/2 * nTRs
      indices <- seq(0, maximum, length.out = length(fdat))
      graphics::par(mar = c(3, 3, 1, 1), oma = c(0, 0, 0, 0),
                    lwd = settings$graphics$FreqPlotLineWidth,
                    bg = settings$graphics$FreqPlotBackgroundColor,
                    fg = settings$graphics$FreqPlotLabelColor,
                    col.axis = settings$graphics$FreqPlotLabelColor,
                    col.lab = settings$graphics$FreqPlotLabelColor)
      graphics::plot(indices, fdat, t = "l", xaxp = c(0, max(indices), 7), ylab = "",
                     xlab = "", col = settings$graphics$FreqPlotLineColor)
      graphics::title(ylab = "Power", line = 2)
      graphics::title(xlab = "Frequency (in Hz)", line = 2)
    },
    drawMotion = function(tdat, motionDat, TR) {
      visible(widgets$TimePlot) <<- TRUE
      rnge <- max(tdat) - min(tdat)
      mdat <- motionDat/max(motionDat) * rnge/2
      mdat <- mdat + mean(range(tdat))
      seconds <- TR * 1:length(mdat)
      alphaNum <- round((settings$graphics$MotionPlotLineAlpha/100) * 256)
      alphaStr <- sprintf("%0.2x", alphaNum)
      lineColor <- paste(settings$graphics$MotionPlotLineColor, alphaStr, sep = "")
      graphics::lines(seconds, mdat, col = lineColor, lwd = settings$graphics$TimePlotLineWidth)
    },
    drawTimeCourse = function(tdat, TR) {
      visible(widgets$TimePlot) <<- TRUE
      graphics::par(mar = c(3, 3, 1, 1), oma = c(0, 0, 0, 0),
                    lwd = settings$graphics$TimePlotLineWidth,
                    bg = settings$graphics$TimePlotBackgroundColor,
                    fg = settings$graphics$TimePlotLabelColor,
                    col.axis = settings$graphics$TimePlotLabelColor,
                    col.lab = settings$graphics$TimePlotLabelColor)
      seconds <- TR * 1:length(tdat)
      graphics::plot(seconds, tdat, t = "l", ylab = "", xlab = "",
                     col = settings$graphics$TimePlotLineColor)
      graphics::title(ylab = "Normalized Response", line = 2)
      graphics::title(xlab = paste("Time (seconds); TR =", TR, "s"), line = 2)
    },
    drawTimeFigures = function(compNum) {
      if(is.null(data$TIMEDATFILES)) return()
      tdatFile <- data$TIMEDATFILES[compNum]
      fdatFile <- data$FREQDATFILES[compNum]
      tdat <- utils::read.table(tdatFile)[[1]]
      fdat <- utils::read.table(fdatFile)[[1]]
      nTRs <- length(tdat)
      drawTimeCourse(tdat, data$TR)
      if (svalue(widgets$ShowMotionCheckbox))
        drawMotion(tdat, data$MOTIONDAT, data$TR)
      drawFrequency(fdat, data$TR, nTRs)
    },
    drawBrains = function(compNum) {
      # heat colors
      heatcols <- grDevices::heat.colors(2000)
      # cool colors
      coolcols <- grDevices::topo.colors(10000)[900:3300]
      visible(widgets$MainPlot) <<- TRUE
      bgCol <- paste0("gray", settings$graphics$brainBackgroundValue)
      braincols <- grDevices::gray.colors(n = 20000, start = 0,
                                          end = settings$graphics$brainColValue, gamma = 0.6)

      # If we haven't loaded a standard yet, then we can't draw its data
      if(is.null(data$STANDARDDATA)) {
        startSlice <- 1
        endSlice <- dim(data$MELDATA)[3]
      } else {
        startSlice <- data$STARTSLICE
        endSlice <- data$ENDSLICE
      }
      thisbraindat <- data$MELDATA[, , , compNum]
      sliceIndices <- seq(startSlice, endSlice, settings$graphics$skipSlices)
      nCols <- settings$graphics$numBrainCols
      nRows <- ceiling(length(sliceIndices)/nCols)
      graphics::par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0),
                    mfrow = c(nRows, nCols), bg = bgCol)
      rnge <- range(thisbraindat)
      for (i in sliceIndices) {
        if (!is.null(data$STANDARDDATA)) {
          graphics::image(data$STANDARDDATA[, , i], col = braincols, axes = F,
                          useRaster = T, zlim = c(.1, max(data$STANDARDDATA[, , i])))
        } else {
          graphics::plot.new()
        }
        if (rnge[2] > 0 && rnge[2] > settings$graphics$Threshold)
          graphics::image(thisbraindat[, , i], col = heatcols, axes = F,
                          useRaster = T, zlim = c(settings$graphics$Threshold, rnge[2]),
                          add = T)
        if (rnge[1] < 0 && abs(rnge[1]) > settings$graphics$Threshold)
          graphics::image(thisbraindat[, , i] * -1, col = coolcols,
                          axes = F, useRaster = T,
                          zlim = c(settings$graphics$Threshold, abs(rnge[1])), add = T)
      }
    },
    initializePlot = function() {
      data$COMPTABLE <<- data.frame(array(dim = c(data$NCOMPS, 3)), stringsAsFactors = FALSE)
      names(data$COMPTABLE) <<- c("IC", "ClassName", "To_Remove")
      if (nrow(data$COMPTABLE) > 0) {
        data$COMPTABLE$IC <<- 1:data$NCOMPS
        data$COMPTABLE$ClassName <<- ""
        data$COMPTABLE$To_Remove <<- ""
      }
      widgets$CompTable[] <<- data$COMPTABLE
      if (nrow(data$COMPTABLE) > 0) {
        drawTimeFigures(1)
        svalue(widgets$CompTable) <<- 1
        drawBrains(1)
        svalue(widgets$MainPlotLabel) <<- 1
        prevClass <- loadClassificationFile()
        if (!is.null(prevClass) && nrow(prevClass) == nrow(widgets$CompTable[]))
          widgets$CompTable[] <<- prevClass
      }
      if (is.null(data$HANDLERID))
        data$HANDLERID <<- addHandlerClicked(widgets$CompTable, handler = updatePlots)
    },
    loadStandard = function(...) {

      standarddat <- RNifti::readNifti(data$STANDARDFILE)
      if (!identical(dim(standarddat), data$MELDIM)) {
        gmessage("The voxel dimensions of the standard Nifti file must match those of \
                 the melodic_IC file in the ICA directory.", title = "Voxel Dimensions Match Error",
                 icon = "error")
        return()
      }

      data$STANDARDDATA <<- standarddat

      # find first and last slices that aren't all 0s
      for (i in 1:dim(data$STANDARDDATA)[3]) {
        if (!all(data$STANDARDDATA[, , i] == 0)) {
          data$STARTSLICE <<- i
          break()
        }
      }
      for (i in dim(data$STANDARDDATA)[3]:data$STARTSLICE) {
        if (!all(data$STANDARDDATA[, , i] == 0)) {
          data$ENDSLICE <<- i
          break()
        }
      }
      updatePlots(NULL)
    },
    getTR = function() {
      logfile <- paste0(data$ICADIR, '/log.txt')
      if(!file.exists(logfile)) {
        gmessage("Warning: No log file was found in the ICA directory specified. A TR of 1 second will be assumed when \
                 creating timecourse and powerspectrum plots.")
        TR <- 1
      } else {
        logtxt <- scan(paste(data$ICADIR, "/log.txt", sep = ""), "character", quiet = TRUE)
        TRstring <- grep("--tr=", logtxt, value = TRUE)
        TR <- as.numeric(gsub("--tr=", "", TRstring))
      }
      if(length(TR) < 1) {
        return(NULL)
      } else {
        return(TR)
      }
    },
    colorPickerHandler = function(h, ...) {
      # note, this handler will only work with widgets that have an 'action' defined
      newColor <- colorPicker()
      if (is.na(newColor))
        return()
      settings$graphics[h$action] <<- newColor
      drawTimeFigures(svalue(widgets$CompTable))
    },
    getICADIR =  function(...) {
      data$ICADIR <<- gfile(type = "selectdir", initialfilename = ".")
      testICADIR(data$ICADIR)
      loadICADIR()
    },
    loadICADIR = function() {
      ICADIR <- data$ICADIR

      # get number of components
      datfile <- list.files(ICADIR, pattern = '^melodic_IC.nii.*', full.names = TRUE)
      svalue(widgets$statusBar) <<- paste("Now loading", datfile); Sys.sleep(.1)
      data$MELDATA <<- RNifti::readNifti(datfile)
      svalue(widgets$statusBar) <<- paste(datfile, "loaded."); Sys.sleep(.1)
      data$NCOMPS <<- dim(data$MELDATA)[4]
      data$MELDIM <<- dim(data$MELDATA)[1:3]

      # report directory must be present to find time and frequency files
      reportDir <- paste0(ICADIR, '/report')
      if (!dir.exists(reportDir)) {
        gmessage("There is no 'report' directory in the ICA directory specified, so \
                 melviewr will be unable to load timecourse and powerspectrum data files.",
                 title = "Warning", icon = "warning", parent = win)
      } else {
        # get time and frequency images
        tFiles <- gtools::mixedsort(list.files(reportDir,
                                               pattern = "^t.*txt",
                                               full.names = TRUE))
        fFiles <- gtools::mixedsort(list.files(reportDir,
                                               pattern = "^f.*txt",
                                               full.names = TRUE))
        if(length(tFiles) != length(fFiles) || length(tFiles) != data$NCOMPS) {
          gmessage("There is something wrong with the number of timecourse/powerspectrum files in\
                   the 'report' directory of the provided ICA directory. The t*.txt and f*.txt files should be equal \
                   in number and should also equal the number of volumes in the 'melodic_IC' 4D Nifti file.

                   Until these conditions are met, timecourse and powerspectrum figures cannot be displayed.",
                   title = "Warning", icon = "warning", parent = win)
        } else {
          data$TIMEDATFILES <<- tFiles
          data$FREQDATFILES <<- fFiles
        }
      }

      data$TR <<- getTR()
      initializePlot()
    },
    saveClassificationFile = function(...) {
      dat <- widgets$CompTable[]
      dat2 <- subset(dat, !ClassName %in% c("Signal", "Unknown", ""))
      formatted <- paste(dat2$IC, collapse = ", ")
      formatted <- paste("[", formatted, "]", sep = "")
      outfile <- ""
      outfile <- gfile(type = "save", initialfilename = paste0(data$ICADIR, "/hand_labels_noise.txt"))
      if (outfile != "") {
        sink(outfile)
        writeLines(formatted)
        sink()
        utils::write.csv(dat, paste0(data$ICADIR, "/.classification.csv"), row.names = FALSE, quote = FALSE)
      }
    },
    loadClassificationFile = function() {
      fname <- paste(data$ICADIR, "/.classification.csv", sep = "")
      output <- NULL
      if (file.exists(fname)) {
        output <- utils::read.csv(fname, stringsAsFactors = FALSE)
      }
      return(output)
    },
    getMotionFile = function(h, ...) {
      initialfilename <- ifelse(file.exists("../../Movement_RelativeRMS.txt"), "../../Movement_RelativeRMS.txt", ".")
      motionfile <- gfile("Select Motion File", type = "open", initialfilename = initialfilename)
      if (is.na(motionfile))
        return()
      loadMotionFile(motionfile)
    },
    loadMotionFile = function(motionfile) {
      data$MOTIONFILE <<- motionfile
      motiondata <- utils::read.table(motionfile)
      if (ncol(motiondata) > 1) gmessage("The file you selected has multiple columns. \
                                         Are you sure it is a summarized motion file and not a file with separate columns \
                                         for movement in the x, y, and z directions?", title = "Warning", icon = "warning", parent = win)
      data$MOTIONDATA <<- motiondata[[1]]
        if (!is.null(widgets$ShowMotionCheckbox)) {
        enabled(widgets$ShowMotionCheckbox) <<- TRUE
        enabled(widgets$MotionOptionsToggle) <<- TRUE
        svalue(widgets$ShowMotionCheckbox) <<- TRUE
        drawTimeFigures(svalue(widgets$CompTable))
      }
    },
    updateClassLabel = function(h, ...) {
      compNum <- as.numeric(svalue(widgets$MainPlotLabel))
      thisClassName <- svalue(widgets$ClassificationRadio)
      widgets$CompTable[compNum]$ClassName <<- thisClassName
      widgets$CompTable[compNum]$To_Remove <<- ifelse(!thisClassName %in% c("Signal", "Unknown"), "X", "")
    },
    updatePlots = function(h, ...) {
      "Updates all three plots."
      if (status$suppressRedraw)
        return()
      compNum <- svalue(widgets$CompTable)
      svalue(widgets$MainPlotLabel) <<- compNum
      if (length(widgets$CompTable[compNum]$ClassName) > 0) {
        if (widgets$CompTable[compNum]$ClassName == "") {
          widgets$CompTable[compNum, 2] <<- "Signal"
        }
      }
      svalue(widgets$ClassificationRadio) <<- widgets$CompTable[compNum]$ClassName
      settings$graphics$Threshold <<- as.numeric(svalue(widgets$ThresholdInput))
      settings$graphics$skipSlices <<- svalue(widgets$SkipInput)
      settings$graphics$numBrainCols <<- svalue(widgets$ColNumInput)
      settings$graphics$brainColValue <<- svalue(widgets$BrainColSlider)
      settings$graphics$brainBackgroundValue <<- svalue(widgets$BackgroundSlider)
      drawTimeFigures(compNum)
      drawBrains(compNum)
    },
    saveGraphicsSettings = function(h, ...) {
      "Saves graphics options to a file in the User's HOME directory."
      tryCatch({
        configFile <- paste0(Sys.getenv('HOME'), "/.melviewR.config")
        sink(configFile)
        cat(jsonlite::toJSON(settings$graphics))
        sink()
        output <- list(messageTxt = paste("Config file has been saved to:", configFile), icon = "info")
        gmessage(output$messageTxt, title = "Save Graphics Settings", icon = output$icon)
      }, warning = function(war) {
        output <- list(messageTxt = paste("A warning has been raised in the attempt to save settings to:", configFile, "\n", war),
                       icon = "warning")
        gmessage(output$messageTxt, title = "Save Graphics Settings", icon = output$icon)
      }, error = function(err) {
        output <- list(messageTxt = paste("An error has been raied in the attempt to save settings to:", configFile, "\n", err),
                       icon = "error")
        gmessage(output$messageTxt, title = "Save Graphics Settings", icon = output$icon)
      }, finally = {
        DONE <- TRUE
      })
    },
    loadGraphicsSettings = function() {
      "Loads previously saved graphics options."
      configFile <- paste0(Sys.getenv('HOME'), "/.melviewR.config")
      configLoaded <- FALSE
      if (file.exists(configFile)) {
        tryCatch({
          newSettings <- jsonlite::fromJSON(configFile)
          settings$graphics <<- newSettings
          # if any graphics options are not set in the config file, set them to their default state.
          for (thisSetting in names(settings$graphicsDefaults)) {
            if (is.null(newSettings[[thisSetting]])) {
              settings$graphics <<- settings$graphicsDefaults[[thisSetting]]
            }
          }
          configLoaded <- TRUE
        }, warning = function(war) {
          gmessage(paste("Warning while loading saved graphics settings:", war),
                   icon = 'warning', title = 'Warning')
        }, error = function(err) {
          gmessage(paste("Error while loading saved graphics settings:", err),
                   icon = 'error', title = 'Error')
        })
      }
      return(configLoaded)
    },
    restoreDefaultGraphicsSettings = function(...) {
      "Restores graphics settings to default values."
      settings$graphics <<- settings$graphicsDefaults
      if (!is.null(widgets$freqLineWidthChooser)) {
        status$suppressRedraw <<- TRUE
        svalue(widgets$ColNumInput) <<- settings$graphics$numBrainCols
        svalue(widgets$SkipInput) <<- settings$graphics$skipSlices
        svalue(widgets$ThresholdInput) <<- settings$graphics$Threshold
        svalue(widgets$BrainColSlider) <<- settings$graphics$brainColValue
        svalue(widgets$BackgroundSlider) <<- settings$graphics$brainBackgroundValue
        svalue(widgets$timeCourseLineWidthChooser) <<- settings$graphics$TimePlotLineWidth
        svalue(widgets$freqLineWidthChooser) <<- settings$graphics$FreqPlotLineWidth
        svalue(widgets$motionLineAlphaChooser) <<- settings$graphics$MotionPlotLineAlpha
        status$suppressRedraw <<- FALSE
        updatePlots(NULL)
      }
    }
  )
)

createViewrObject <- function() {
  viewr <- Viewr$new(
    status = list(
      suppressRedraw = FALSE,
      exit = FALSE
    ),
    settings = list(
      graphicsDefaults = list(
        skipSlices = 3,
        numBrainCols = 9,
        Threshold = 2.3,
        brainColValue = 0.5,
        brainBackgroundValue = 0,
        TimePlotLineColor = "black",
        TimePlotLineWidth = 0.5,
        TimePlotBackgroundColor = "white",
        TimePlotLabelColor = "black",
        FreqPlotLineColor = "black",
        FreqPlotLineWidth = 0.5,
        FreqPlotBackgroundColor = "white",
        FreqPlotLabelColor = "black",
        MotionPlotLineColor = "#FF0000",
        MotionPlotLineAlpha = 50
      )
    ),
    data = list(
      ICADIR = NULL,
      MOTIONFILE = NULL,
      MOTIONDATA = NULL,
      MELDATA = NULL,
      STANDARDFILE = NULL,
      STANDARDDATA = NULL,
      FSLDIR = NULL,
      MELDIM = NULL,
      NCOMPS = 0,
      TR = NULL,
      COMPTABLE = data.frame(array(dim = c(0, 3)),
                             stringsAsFactors = FALSE),
      TIMEDATFILES = NULL,
      FREQDATFILES = NULL,
      STARTSLICE = NULL,
      ENDSLICE = NULL,
      HANDLERID = NULL
    )
  )
  names(viewr$data$COMPTABLE) <- c("IC", "ClassName", "To_Remove")
  return(viewr)
}  # End createViewrObject
#==============================================================================#




#==============================================================================#
# Main function the user will see.
#' melviewr: View and Classify Components from a Melodic Analysis
#'
#' The melviewr GUI allows for convenient viewing and classification of the
#' results of a single-subject MELODIC analysis. Classification can then be
#' saved to a text file for use by ICA+FIX to train its classifier. Various
#' graphics options are available in the GUI, and these settings can be saved
#' via a button in the GUI.
#' @param melodic_dir string Path to MELODIC output directory. This directory
#' must include a melodic_IC.nii or melodic_IC.nii.gz file.
#' @param standard_file string Optional path to a 3-dimensional Nifti standard file
#' of the same voxel dimensions as the melodic output
#' @param motion_file string Optional path to a summary motion text file. This file
#' should have one column and as many rows as there are volumes in the functional
#' data
#' @export
#' @import gWidgets
#' @import gWidgetsRGtk2
#' @importFrom methods new
#' @return Invisibly returns a reference class object of class "Viewr"
#' @details The directory specified in \code{melodic_dir} must contain a nifti
#' file called either "melodic_IC.nii.gz" or "melodic_IC.nii" for the GUI to run.
#' It must have a directory called "report" with text files inside in order to
#' display timecourse and powerspectrum plots. Normally, this directory is
#' created automatically with the \code{-report} flag in MELODIC.
#'
#' When saving graphical settings, a JSON file is saved in the user's HOME
#' directory with the name: \code{.melviewR.config}
#' @examples \dontrun{
#' melodic_dir <- system.file("extdata", "example.ica", package = "melviewr")
#' standard_file <- system.file("extdata", "MNI152_T1_2mm_brain.nii.gz", package = "melviewr")
#' motion_file <- system.file("extdata", "Movement_RelativeRMS.txt", package = "melviewr")
#' melviewr(melodic_dir)
#' melviewr(melodic_dir, standard_file)
#' melviewr(melodic_dir, standard_file, motion_file)}
melviewr <- function(melodic_dir, standard_file = NULL, motion_file = NULL) {
    # Keep environment tidy
    old <- options(stringsAsFactors = FALSE)
    on.exit(options(old), add = TRUE)
    options(guiToolkit = "RGtk2")

    # make viewr object
    viewr <- createViewrObject()

    # test validity of inputs
    melodic_dir <- normalizePath(melodic_dir)
    testICADIR(melodic_dir)
    if (!is.null(standard_file)) {
      testStandardFile(standard_file)
      viewr$data$STANDARDFILE <- normalizePath(standard_file)
    }
    if (!is.null(motion_file)) {
      testMotionFile(motion_file)
      viewr$data$MOTIONFILE <- normalizePath(motion_file)
      viewr$loadMotionFile(viewr$data$MOTIONFILE)
    }
    # move to melodic dir (might not be necessary)
    oldwd <- setwd(melodic_dir)
    on.exit(setwd(oldwd), add = TRUE)

    # Begin loading data
    viewr$data$ICADIR <- melodic_dir

    if (!viewr$loadGraphicsSettings())
      viewr$settings$graphics <- viewr$settings$graphicsDefaults


    viewr$createGUI()
    viewr$loadICADIR()
    if (!is.null(standard_file)) viewr$loadStandard()

    waitForExit <- function(...) {
      while (!viewr$status$exit) {
        Sys.sleep(1)
      }
    }

    addHandlerUnrealize(viewr$win , handler = function(h, ...) {
      viewr$status$exit <- TRUE
      dispose(viewr$win)
    })

    if (!interactive()) {
      waitForExit()
    }

    invisible(viewr)
}  # End melviewr function definition
#==============================================================================#


