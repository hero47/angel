package angel.common {
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Util {
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_I:uint = 73;
		public static const KEYBOARD_M:uint = 77;
		public static const KEYBOARD_V:uint = 86;
		
		public function Util() {
			
		}
		
		public static function traceXml(xml:XML):void {
			var debug:XML = new XML("<debug/>");
			debug.appendChild(xml.copy());
			trace(debug);
		}
		
		public static function saveXmlToFile(xml:XML, defaultFilename:String):void {
			// convert xml to binary data
			var ba:ByteArray = new ByteArray( );
			ba.writeUTFBytes( xml );
 
			// save to disk
			var fr:FileReference = new FileReference( );
			fr.save( ba, defaultFilename );
		}
		
		public static function addBelow(newObject:DisplayObject, existingObject:DisplayObject, gap:int = 0):void {
			newObject.x = existingObject.x;
			newObject.y = existingObject.y + existingObject.height + gap;
			existingObject.parent.addChild(newObject);
		}
		
		public static function addBeside(newObject:DisplayObject, existingObject:DisplayObject, gap:int = 0):void {
			newObject.y = existingObject.y;
			newObject.x = existingObject.x + existingObject.width + gap;
			existingObject.parent.addChild(newObject);
		}

		public static function createTextEditControlBelow(previousControl:DisplayObject, labelText:String, labelWidth:int, fieldWidth:int, changeHandler:Function, optionalXInsteadOfAligning:int = int.MAX_VALUE):TextField {
			var textField:TextField = Util.textBox("", fieldWidth, 20, TextFormatAlign.LEFT, true);
			if (labelText != null) {
				var label:TextField = Util.textBox(labelText + ":", labelWidth, 20);
				addBelow(label, previousControl, 5);
				if (optionalXInsteadOfAligning != int.MAX_VALUE) {
					label.x = optionalXInsteadOfAligning;
				}
				addBeside(textField, label, 5);
			} else {
				addBelow(textField, previousControl, 5);
				if (optionalXInsteadOfAligning != int.MAX_VALUE) {
					textField.x = optionalXInsteadOfAligning;
				}
			}
			if (changeHandler != null) {
				textField.addEventListener(Event.CHANGE, changeHandler);
			}
			return textField;
		}

		public static function createCheckboxEditControlBelow(previousControl:DisplayObject, labelText:String, width:int, changeHandler:Function):CheckBox {
			var checkBox:CheckBox = new CheckBox();
			checkBox.label = labelText;
			checkBox.width = width;
			addBelow(checkBox, previousControl, 5);
			if (changeHandler != null) {
				checkBox.addEventListener(Event.CHANGE, changeHandler);
			}
			return checkBox;
		}
		
		public static const DEFAULT_TEXT_WIDTH:int = 100;
		public static const DEFAULT_TEXT_HEIGHT:int = 20;
		public static function textBox(text:String, width:int = DEFAULT_TEXT_WIDTH, height:int = DEFAULT_TEXT_HEIGHT, align:String = TextFormatAlign.LEFT,
					editable:Boolean=false, textColor:uint = 0):TextField {
			var myTextField:TextField = new TextField();
			myTextField.textColor = textColor;
			myTextField.backgroundColor = (textColor > 0x880000 ? 0 : 0xffffff); // but won't be visible unless you set background=true
			myTextField.selectable = editable;
			myTextField.width = width;
			myTextField.height = height;
			myTextField.type = (editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC);
			myTextField.border = editable;
			
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.size = height - 6;
			myTextFormat.align = align;
			myTextField.defaultTextFormat = myTextFormat;
			
			myTextField.text = text;
			return myTextField;
		}
		
		public static function nullSafeSetText(textField:TextField, value:String):void {
			textField.text = (value == null ? "" : value);
		}
		
		// It baffles me that ComboBox doesn't provide this as a built-in
		// (If two or more entries have the same label, this just finds the first one)
		public static function itemWithLabelInComboBox(combo:ComboBox, label:String):Object {
			if (label == null) {
				label = "";
			}
			for (var i:int = 0; i < combo.length; ++i) {
				var item:Object = combo.getItemAt(i);
				if (combo.itemToLabel(item) == label) {
					return item;
				}
			}
			return null;
		}
		
		public static function pointOnCircleFromFacing(radius:Number, facing:Number, center:Point = null):Point {
			var loc:Point = new Point();

			loc.x = radius*Math.cos(facing*(Math.PI/180));
            loc.y = radius*Math.sin(facing*(Math.PI/180));
			if (center != null) {
				loc.x += center.x;
				loc.y += center.y;
			}
            return loc;
		}
		
		public static function findRotFacingVector(vector:Point):Number {
			return Math.atan2(vector.y, vector.x ) * 180 / Math.PI;
		}

		// Fisher-Yates shuffle
		// declaring v:Vector isn't allowed, but Object works. Yay CS5.
		public static function shuffle(v:Object):void {
			for (var i:int = v.length - 1; i > 0; i--)
			{
				var j:int = Math.floor(Math.random() * (i + 1));
				if (j != i) {
					var temp:* = v[i];
					v[i] = v[j];
					v[j] = temp;
				}
			}
		}
		
		public static function sign(foo:int):int {
			return (foo < 0 ? -1 : (foo > 0 ? 1 : 0));
		}
		
		public static function chessDistance(a:Point, b:Point):int {
			return Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));
		}
		
		// startAngle should be multiple of 45 degrees; it's the facing to the first point on circle. Half continues clockwise.
		public static function halfCircle(g:Graphics, x:Number,y:Number,r:Number, startAngle:int):void {
			var c1:Number=r * (Math.SQRT2 - 1);
			var c2:Number = r * Math.SQRT2 / 2;
			var start:int = ((startAngle +360) % 360) / 45;
			var controlX:Number;
			var controlY:Number;
			var anchorX:Number;
			var anchorY:Number;
			
			
			for (var i:int = start; i < start + 5; i++) {
				switch (i % 8) {
					case 0:
						controlX = x + r;
						controlY = y - c1;
						anchorX = x + r;
						anchorY = y;
					break;
					case 1:
						controlX = x + r;
						controlY = y + c1;
						anchorX = x + c2;
						anchorY = y + c2;
					break;
					case 2:
						controlX = x + c1;
						controlY = y + r;
						anchorX = x;
						anchorY = y + r;
					break;
					case 3:
						controlX = x - c1;
						controlY = y + r;
						anchorX = x - c2;
						anchorY = y + c2;
					break;
					case 4:
						controlX = x - r;
						controlY = y + c1;
						anchorX =  x - r;
						anchorY = y;
					break;
					case 5:
						controlX = x - r;
						controlY = y - c1;
						anchorX = x - c2;
						anchorY = y - c2;
					break;
					case 6:
						controlX = x - c1;
						controlY = y - r;
						anchorX = x;
						anchorY = y - r;
					break;
					case 7:
						controlX = x + c1;
						controlY = y - r;
						anchorX = x + c2;
						anchorY = y - c2;
					break;	
				}
				if (i == start) {
					g.moveTo(anchorX, anchorY);
				} else {
					g.curveTo(controlX, controlY, anchorX, anchorY);
				}
			}
		};
		
		public static function lineOfSight(room:Room, from:Point, target:Point):Boolean {
			return lineUnblocked(room.blocksSight, from, target);
		}
		
//Outdented lines are for debugging, delete them eventually
public static var debugLOS:Boolean = false;
private static var lastLineOfSightTarget:Point = new Point(-1,-1);
		public static function lineUnblocked(blockTest:Function, from:Point, target:Point):Boolean {		
			var x0:int = from.x;
			var y0:int = from.y;
			var x1:int = target.x;
			var y1:int = target.y;
			var dx:int = Math.abs(x1 - x0);
			var dy:int = Math.abs(y1 - y0);
			
var traceIt:Boolean = debugLOS && !target.equals(lastLineOfSightTarget);
var losPath:Array = new Array();
lastLineOfSightTarget = target;
			// Ray-tracing on grid code, from http://playtechs.blogspot.com/2007/03/raytracing-on-grid.html
			var x:int = x0;
			var y:int = y0;
			var n:int = 1 + dx + dy;
			var x_inc:int = (x1 > x0) ? 1 : -1;
			var y_inc:int = (y1 > y0) ? 1 : -1;
			var error:int = dx - dy;
			dx *= 2;
			dy *= 2;
			
			// original code looped for (; n>0; --n) -- I changed it so the shooter & target don't block themselves
			for (; n > 2; --n) {
losPath.push(new Point(x, y));

				if (error > 0) {
					x += x_inc;
					error -= dy;
				}
				else if (error < 0) {
					y += y_inc;
					error += dx;
				} else { // special case when passing directly through vertex -- do a diagonal move, hitting one less tile
					//CONSIDER: we may want to call this blocked if the tiles we're going between have "hard corners"
					x += x_inc;
					y += y_inc;
					error = error - dy + dx;
					--n;
					if (n <= 2) {
						break;
					}
				}
				// moved this check to end of loop so we're not checking the shooter's own tile
				if (blockTest(x, y)) {
if (traceIt) { trace("Blocked; path", losPath);}
					return false;
				}
			}
if (traceIt) { losPath.push(new Point(x, y));  trace("LOS clear; path", losPath); }
			return true;
		} // end function lineOfSight
		
		public static function entityHasLineOfSight(entity:ComplexEntity, target:Point):Boolean {
			return Util.lineOfSight(entity.room, entity.location, target);
		}
		
	} // end class Util

}