package angel.game.test {
	import angel.common.Alert;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Autotest {
		
		public static var failCount:int = 0;
		public static var runningFromRoot:Sprite;
		
		public function Autotest() {
		}
		
		public static function assertTrue(test:Boolean, message:String = ""):void {
			if (!test) {
				fail(message);
			}
		}
		
		public static function assertFalse(test:Boolean, message:String = ""):void {
			if (test) {
				fail(message);
			}
		}
		
		public static function assertEqual(val1:*, val2:*, message:String = ""):void {
			if (val1 != val2) {
				fail("[" + val1 + "] != [" + val2 + "] " + message);
			}
		}
		
		public static function assertNotEqual(val1:*, val2:*, message:String = ""):void {
			if (val1 == val2) {
				fail("[" + val1 + "] " + message);
			}
		}
		
		public static function clearAlert():void {
			Alert.messageForTestMode = null;
		}
		
		public static function assertNoAlert(message:String = ""):void {
			if (Alert.messageForTestMode != null) {
				fail("Alert: [" + Alert.messageForTestMode + "] " + message);
			}
			clearAlert();
		}
		
		public static function assertAlerted(message:String = ""):void {
			if (Alert.messageForTestMode == null) {
				fail("Should have alerted. " + message);
			}
			clearAlert();
		}
		
		public static function assertAlertText(text:String, message:String = ""):void {
			if (Alert.messageForTestMode != text) {
				fail("Alert [" + Alert.messageForTestMode + "], expected [" + text + "] " + message);
			}
			clearAlert();
		}
		
		public static function fail(message:String):void {
			trace(failureFileAndLineNumber(), message);
			failCount++;
		}
		
		public static function runTest(testClass:Class):void {
			trace("Running:", testClass);
			clearAlert();
			new testClass();
			assertNoAlert("Something in " + testClass + " caused an alert.");
		}
		
		public static function testFunction(testFunction:Function):void {
			assertNoAlert("Leftover alert before testFunction");
			testFunction();
			assertNoAlert("Something in a tested function caused an alert.");
		}
		
		private static function failureFileAndLineNumber(): String {
			try { throw new Error(); }
			catch (e:Error) { 
				return firstNonAutotestFileAndLine(e.getStackTrace()); 
			}
			return "";
		}

		public static function firstNonAutotestFileAndLine(stack:String):String {
			var lines:Array = stack.split("\n");
			// line 0 is just "Error", skip it
			for (var i:int = 1; i < lines.length; i++) {
				if (lines[i].indexOf("Autotest") < 0) {
					var lastBackslash:int = lines[i].lastIndexOf("\\");
					return "[" + lines[i].substr(lastBackslash + 1);
				}
			}
			return "?";
			/* Full stack trace:			
			// remove the path
			// it's too long and we can get the info from the method trace
			var regEx:RegExp = /\w:[\\\/]([\w-]+[\\\/])*\w+.as/ig;
			var newStack:String = new String("\n");
			for (var i:int = 0; i < lines.length; i++) {
				var line:String = lines[i];
				line = line.replace(regEx, "");
				line = line.replace("[:", " [line:");
				newStack = newStack + line + "\n";
			}
			return newStack;
			*/
		}
		
	}

}