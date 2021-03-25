using Toybox.WatchUi;
using Toybox.Graphics;

class absoluteavgspeedView extends WatchUi.DataField {

    hidden var hasBackgroundColorOption = false;
    hidden var mValue;
    hidden var mDeclining = false;
    hidden var oldDistance, oldTime, lastCheck = 0;
	hidden var metric = true;

	hidden var labelText, labelPos, unit1, unit2;
	hidden var valuePos = [ [ 0, 0 ], [ 0, 0 ] ], unit1Pos = [ [ 0, 0 ], [ 0, 0 ] ], unit2Pos = [ [ 0, 0 ], [ 0, 0 ] ];

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

		// Label things
		labelText = WatchUi.loadResource(Rez.Strings.label);
		labelPos = [ Math.floor(width / 2), 3 ]; // This is shown as centered so no need adjust x position according to text width

		var textHeight = dc.getFontHeight(VALUE_FONT);
		var unitHeight = dc.getFontHeight(UNIT_FONT);
		var unit1Width = dc.getTextWidthInPixels(unit1, UNIT_FONT);

		calculatePosForText(dc, 0, "88.8", width, height, textHeight, unitHeight, unit1Width);
		calculatePosForText(dc, 1, "8.8", width, height, textHeight, unitHeight, unit1Width);

        return true;
    }

    // calculate positions for the given text and put it in valuePos[idx], unit1Pos[idx] and unit2Pos[idx]
    function calculatePosForText(dc, idx, text, width, height, textHeight, unitHeight, unit1Width) {
		var textWidth = dc.getTextWidthInPixels(text, VALUE_FONT);

		var vp = [ Math.floor((width - textWidth) / 2) - 4, Math.floor((height - textHeight) / 2) + 14 ];
		var u1p = [ vp[0] + textWidth + 4, vp[1] ];
		var u2p = [ u1p[0] + (metric ? Math.floor(unit1Width/3) : 3), u1p[1] + unitHeight - 4 ];

		valuePos[idx] = vp;
		unit1Pos[idx] = u1p;
		unit2Pos[idx] = u2p;
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
			lastCheck = 0;
			return;
		}

		var et = info.elapsedTime.toFloat();

//		System.println("elapsed d=" + info.elapsedDistance + " t=" + info.elapsedTime);
		var val = info.elapsedDistance / (et / 1000.0f); // m/s
		mValue = metric ? val * 3.6 :  val * 2.23694;

		// threshold is 2 and 3 seconds depending on if we're "declining" or not, so it's hard to get into "declining" but easy to bounce back
		// allow for drift of 200ms because if we miss the mark, next invocation is probably 1s later, which is too long for us
		var checkThreshold = mDeclining ? 1800 : 2800;

		if (lastCheck == 0 || lastCheck > et) {
//			System.println("reset lastcheck");
			lastCheck = et;
		} else if (et - lastCheck > checkThreshold) {
			mDeclining = info.elapsedDistance == oldDistance && et > oldTime;
//			if (mDeclining) {
//				System.println("checking mDeclining: YES");
//			} else {
//				System.println("checking mDeclining: no");
//			}

			oldDistance = info.elapsedDistance;
			oldTime = et;
			lastCheck = et;
		}

		if (mValue < 0.01f) {
			mValue = 0;
		}
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
		var idx = 0;

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
					idx = 1; // Use single-digit positions if we're in single digits
				}
			}
		}

		// Label
		dc.drawText(labelPos[0], labelPos[1], LABEL_FONT, labelText, Graphics.TEXT_JUSTIFY_CENTER);

		// Value
		dc.drawText(valuePos[idx][0], valuePos[idx][1], VALUE_FONT, text, Graphics.TEXT_JUSTIFY_LEFT);

		// Unit
		dc.drawText(unit1Pos[idx][0], unit1Pos[idx][1], UNIT_FONT, unit1, Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(unit2Pos[idx][0], unit2Pos[idx][1], UNIT_FONT, unit2, Graphics.TEXT_JUSTIFY_LEFT);
    }

}
