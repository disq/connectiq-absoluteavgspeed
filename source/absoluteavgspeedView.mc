using Toybox.WatchUi;
using Toybox.Graphics;

class absoluteavgspeedView extends WatchUi.DataField {

    hidden var hasBackgroundColorOption = false;
    hidden var mValue;
	hidden var metric = true;

	const VALUE_DISABLED = -1.0f;

    function initialize() {
        DataField.initialize();

        var sys = System.getDeviceSettings();
        metric = sys.distanceUnits != System.UNIT_STATUTE;

        hasBackgroundColorOption = (self has :getBackgroundColor);
        mValue = VALUE_DISABLED;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));

        // "Centered" manual layout
        var labelView = View.findDrawableById("label");

        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY + 14;

        labelView.setText(Rez.Strings.label);
        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        // See Activity.Info in the documentation for available information.

       if (info == null || info.elapsedTime == null || info.elapsedTime <= 0 || (!(info has :elapsedDistance)) || info.elapsedDistance == null) {
			mValue = VALUE_DISABLED;
			return;
		}

//		System.println("elapsed d=" + info.elapsedDistance + " t=" + info.elapsedTime);
		var val = info.elapsedDistance / (info.elapsedTime.toFloat() / 1000.0f); // m/s
		mValue = metric ? val * 3.6 :  val * 2.23694;
	}

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
	function onUpdate(dc) {
		var backgroundColor, textColor;

		if (hasBackgroundColorOption) {
			backgroundColor = getBackgroundColor();
			if (backgroundColor == Graphics.COLOR_BLACK) {
				// night
				textColor = Graphics.COLOR_WHITE;
			} else {
				// daylight
				textColor = Graphics.COLOR_BLACK;
			}
		} else {
			backgroundColor = Graphics.COLOR_WHITE;
			textColor = Graphics.COLOR_BLACK;
		}

		// Set the background color
		View.findDrawableById("Background").setColor(backgroundColor);

		// Set label color
		var label = View.findDrawableById("label");
		label.setColor(textColor);

		// Set the foreground color and value
		var value = View.findDrawableById("value");
		value.setColor(textColor);

		var text/*, units*/;

		if (mValue == VALUE_DISABLED || mValue < 0.0f) {
			text = "__.__";
//			units = "";
		} else {
			if (mValue >= 100.0f) {
				if (mValue >= 999.9f) {
					text = "999.9";
				} else {
					text = mValue.format("%.1f");
				}
			} else {
				text = mValue.format("%.2f");
			}
//			units = metric ? "kph" : "mph";
		}

		value.setText(text);       

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
