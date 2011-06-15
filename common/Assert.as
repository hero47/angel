package angel.common {
	import flash.system.Capabilities;

	// UNDONE: investigate compile options and see if I can make this debug-only!
	// Stack trace & filter from http://blog.rough-sea.com/tag/assertions/
	public class Assert {
		
		public function Assert() {
			
		}
		
		public static function fail(message:String):void {
			assertMessage(message);
		}
		
		public static function assertTrue(check:Boolean, message:String):void {
			if (!check) {
				assertMessage(message);
			}
		}
		
		public static function assertFalse(check:Boolean, message:String):void {
			if (check) {
				assertMessage(message);
			}
		}
		
		private static function assertMessage(message:String):void {
			message = "Assert failed!\n" + message + "\n" + getStackTrace();
			Alert.show(message);
			trace(message);
		}
		
		/**
		 * Returns the stack trace (filtered)
		 * @return stack trace
		 */
		public static function getStackTrace():String {
			if (!Capabilities.isDebugger) {
				return "Stack trace not available in non-debugger version.";
			}
			try { throw new Error(); }
			catch (e:Error) { return filterStackTrace(e.getStackTrace()); }
			return "";
		}

		public static function filterStackTrace(stack:String):String {
			var lines:Array = stack.split("\n");
			// remove the path
			// it's too long and we can get the info from the method trace
			var regEx:RegExp = /\w:[\\\/]([\w-]+[\\\/])*\w+.as/ig;
			var newStack:String = new String("");
			lines.shift(); // remove header line
			while (lines[0].indexOf("Assert$") >= 0) {
				lines.shift();
			}
			for (var i:int = 0; i < lines.length; i++) {
				var line:String = lines[i];
				line = line.replace(regEx, "");
				line = line.replace("[:", " [line:");
				newStack = newStack + line + "\n";
			}
			return newStack;
		}
		
	}

}