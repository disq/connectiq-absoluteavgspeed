using Toybox.WatchUi;
using Toybox.Graphics;

class absoluteavgspeedView extends WatchUi.DataField {

    hidden var hasBackgroundColorOption = false;
    hidden var mValue;
    hidden var mDeclining = false;
    hidden var oldDistance, oldTime;
	hidden var metric = true;

	hidden var labelText, labelPos, valuePos, unit1Pos, unit2Pos, unit1, unit2;

	const VALUE_DISABLED = -1.0f;
	const LABEL_FONT = Graphics.FONT_SYSTEM_SMALL;
	const VALUE_FONT = Graphics.FONT_SYSTEM_NUMBER_MEDIUM;
	const UNIT_FONT = Graphics.FONT_SYSTEM_TINY;

    function initialize() {
        DataField.initialize();

        var sys = System.getDeviceSettings();
		metric = sys.distanceUnits != System.UNIT_STATUTE;
		unit1 = metric ? "km" : "m";
		unit2 = "h";

        hasBackgroundColorOption = (self has :getBackgroundColor);
        mValue = VALUE_DISABLED;
        oldDistance = VALUE_DISABLED;
        oldTime = VALUE_DISABLED;
        mDeclining = false;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
		var width = dc.getWidth();
		var height = dc.getHeight();
		var halfWidth = Math.floor(width / 2);

		// Label things
		labelText = WatchUi.loadResource(Rez.Strings.label);
		labelPos = [ halfWidth, 3 ]; // This is shown as centered so no need adjust x position according to text width

		var textWidth = dc.getTextWidthInPixels("88.8", VALUE_FONT);
		var textHeight = dc.getFontHeight(VALUE_FONT);
		var unitHeight = dc.getFontHeight(UNIT_FONT);
		var unit1Width = dc.getTextWidthInPixels(unit1, UNIT_FONT);

		valuePos = [ Math.floor((width - textWidth) / 2) - 4, Math.floor((height - textHeight) / 2) + 14 ];
		unit1Pos = [ valuePos[0] + textWidth + 4, valuePos[1] ];
		unit2Pos = [ unit1Pos[0] + (metric ? Math.floor(unit1Width/3) : 3), unit1Pos[1] + unitHeight - 4 ];

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
			oldDistance = VALUE_DISABLED;
			oldTime = VALUE_DISABLED;
			mDeclining = false;
			return;
		}

//		System.println("elapsed d=" + info.elapsedDistance + " t=" + info.elapsedTime);
		var val = info.elapsedDistance / (info.elapsedTime.toFloat() / 1000.0f); // m/s
		mValue = metric ? val * 3.6 :  val * 2.23694;
		mDeclining = info.elapsedDistance == oldDistance && info.elapsedTime.toFloat() > oldTime;

		oldDistance = info.elapsedDistance;
		oldTime = info.elapsedTime.toFloat();
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

		if (mValue != VALUE_DISABLED && mDeclining) {
			// Invert colours if decreasing
			dc.setColor(backgroundColor, textColor);
			dc.clear();
			dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
		} else {
			dc.setColor(textColor, backgroundColor);
			dc.clear();
			dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
		}

		var text;

		if (mValue == VALUE_DISABLED || mValue < 0.0f) {
			text = "__._";
		} else {
			if (mValue >= 999.9f) {
				text = "999";
			} else if (mValue >= 100.0f) {
				text = mValue.format("%.0f");
			} else {
				text = mValue.format("%.1f");
				if (mValue < 10.0f) {
					text = "0" + text; // %2.1f doesn't work?
				}
			}
		}

		// Label
		dc.drawText(labelPos[0], labelPos[1], LABEL_FONT, labelText, Graphics.TEXT_JUSTIFY_CENTER);

		// Value
		dc.drawText(valuePos[0], valuePos[1], VALUE_FONT, text, Graphics.TEXT_JUSTIFY_LEFT);

		// Unit
		dc.drawText(unit1Pos[0], unit1Pos[1], UNIT_FONT, unit1, Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(unit2Pos[0], unit2Pos[1], UNIT_FONT, unit2, Graphics.TEXT_JUSTIFY_LEFT);
    }

}
