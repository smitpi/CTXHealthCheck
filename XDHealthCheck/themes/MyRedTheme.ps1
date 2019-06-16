$MyRedTheme = New-UDTheme -Name "MyRedTheme" -Definition @{
	UDDashboard = @{
        BackgroundColor = "rgb(229, 229, 229)"
        FontColor       = "rgb(0, 0, 0)"
    }
	UDNavBar = @{
		BackgroundColor = "rgb(202, 0, 28)"
		FontColor       = "rgb(0, 0, 0)"
	}
	UDFooter    = @{
		BackgroundColor = "rgb(202, 0, 28)"
		FontColor       = "rgb(0, 0, 0)"
	}
	UDCard      = @{
		BackgroundColor = "rgb(229, 229, 229)"
		FontColor       = "rgb(0, 0, 0)"
	}
	UDInput     = @{
		BackgroundColor = "rgb(229, 229, 229)"
		FontColor       = "rgb(0, 0, 0)"
	}
	UDTable     = @{
		BackgroundColor = "rgb(229, 229, 229)"
		FontColor       = "rgb(0, 0, 0)"
	}
	UDGrid     = @{
		BackgroundColor = "rgb(229, 229, 229)"
		FontColor       = "rgb(0, 0, 0)"
	}


} -Parent "default"


$SampleTheme = New-UDTheme -Name 'SampleTheme' -Definition @{
	UDDashboard  = @{
		BackgroundColor = "#333333"
		FontColor       = "#FFFFFF"
	}
	UDNavBar     = @{
		BackgroundColor = "#333333"
		FontColor       = "#FFFFFF"
	}
	UDFooter     = @{
		BackgroundColor = "#333333"
		FontColor       = "#FFFFFF"
	}
	UDCard       = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	UDInput      = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	UDGrid       = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	UDChart      = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	UDMonitor    = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	UDTable      = @{
		BackgroundColor = "#444444"
		FontColor       = "#FFFFFF"
	}
	'.btn'       = @{
		'color'            = "#ffffff"
		'background-color' = "#a80000"

	}
	'.btn:hover' = @{
		'color'            = "#ffffff"
		'background-color' = "#C70303"
	}
}

