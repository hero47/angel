package angel.common {
	import flash.display.GradientType;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	// borrowed from Alert class courtesy of http://fatal-exception.co.uk/blog/?p=69
	public class SimplerButton extends SimpleButton implements ICleanup {
		private var callOnClick:Function = null;

		public static const WIDTH:int = 75
		public static const HEIGHT:int = 18;
		
		public function SimplerButton(buttonText:String, callOnClick:Function = null, color:uint = 0x808080, textColor:uint = 0) {
			this.callOnClick = callOnClick;
			var colors:Array = new Array();
			var alphas:Array = new Array(1, 1);
			var ratios:Array = new Array(0, 255);
			var gradientMatrix:Matrix = new Matrix();
			gradientMatrix.createGradientBox(WIDTH, HEIGHT, Math.PI/2, 0, 0);
			//
			var ellipseSize:int = 2;
			var btnUpState:Sprite = new Sprite();
			colors = [0xFFFFFF, color];
			btnUpState.graphics.lineStyle(1, brightenColour(color, -50));
			btnUpState.graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, gradientMatrix);
			btnUpState.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, ellipseSize, ellipseSize);
			btnUpState.addChild(createButtonTextField(buttonText, textColor));
			//
			var btnOverState:Sprite = new Sprite();
			colors = [0xFFFFFF, brightenColour(color, 50)];
			btnOverState.graphics.lineStyle(1, brightenColour(color, -50));
			btnOverState.graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, gradientMatrix);
			btnOverState.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, ellipseSize, ellipseSize);
			btnOverState.addChild(createButtonTextField(buttonText, textColor))
			//
			var btnDownState:Sprite = new Sprite();
			colors = [brightenColour(color, -15), brightenColour(color, 50)];
			btnDownState.graphics.lineStyle(1, brightenColour(color, -50));
			btnDownState.graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, gradientMatrix);
			btnDownState.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, ellipseSize, ellipseSize);
			btnDownState.addChild(createButtonTextField(buttonText, textColor))
			//
			super(btnUpState, btnOverState, btnDownState, btnOverState);
			this.name = buttonText;
			
			if (callOnClick != null) {
				addEventListener(MouseEvent.CLICK, callOnClick);
			}
		}

		public function cleanup():void {
			removeEventListener(MouseEvent.CLICK, callOnClick);
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		public function resizeToFitText(minimumWidth:int = 0):void {
			var sizeNeeded:int = TextField(Sprite(upState).getChildAt(0)).textWidth + 20;
			this.width = (sizeNeeded < minimumWidth ? minimumWidth : sizeNeeded);
		}
		
		private static function brightenColour(colour:int, modifier:int):int {
			var hex:Array = hexToRGB(colour);
			var red:int = keepInBounds(hex[0]+modifier);
			var green:int = keepInBounds(hex[1]+modifier);
			var blue:int = keepInBounds(hex[2]+modifier);
			return RGBToHex(red, green, blue);
		}
		
		private static function createButtonTextField(text:String, textColor:uint = 0):TextField {
			var myTextField:TextField = new TextField();
			myTextField.textColor = textColor;
			myTextField.selectable = false;
			myTextField.width = WIDTH;
			myTextField.height = HEIGHT;
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.align = TextFormatAlign.CENTER;
			myTextField.defaultTextFormat = myTextFormat;
			//text = "<b>"+text+"</b>";
			myTextField.htmlText = '<font face="Verdana">'+text+'</font>';
			myTextField.x = (WIDTH/2)-(myTextField.width/2);
			return myTextField;
		}
		
		private static function hexToRGB (hex:uint):Array {
			var Colours:Array = new Array(); 
			Colours.push(hex >> 16);
			var temp:uint = hex ^ Colours[0] << 16;
			Colours.push(temp >> 8);
			Colours.push(temp ^ Colours[1] << 8);
			return Colours;
		}
		private static function keepInBounds(number:int):int {
			if (number < 0)	number = 0;
			if (number > 255) number = 255;
			return number;
		}		
		private static function RGBToHex(uR:int, uG:int, uB:int):int {
			var uColor:uint;
			uColor =  (uR & 255) << 16;
			uColor += (uG & 255) << 8;
			uColor += (uB & 255);
			return uColor;
		}

	} // end class SimplerButton
	
}