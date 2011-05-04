package angel.common {
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Util {
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_M:uint = 77;
		public static const KEYBOARD_V:uint = 86;
		
		public function Util() {
			
		}

		public static function addTextEditControl(parent:Sprite, previousControl:DisplayObject, labelText:String, labelWidth:int, fieldWidth:int, changeHandler:Function):TextField {
			var label:TextField = Util.textBox(labelText + ":", labelWidth, 20);
			label.y = previousControl.y + previousControl.height + 10;
			parent.addChild(label);
			var textField:TextField = Util.textBox("", fieldWidth, 20, TextFormatAlign.LEFT, true);
			textField.x = label.x + label.width + 5;
			textField.y = label.y;
			textField.addEventListener(Event.CHANGE, changeHandler);
			parent.addChild(textField);
			return textField;
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
		
	} // end class Util

}