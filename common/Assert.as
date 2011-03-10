package angel.common {
	import flash.system.Capabilities;

	// UNDONE: investigate compile options and see if I can make this debug-only!
	// Stack trace & filter from http://blog.rough-sea.com/tag/assertions/
	public class Assert {
		
		public function Assert() {
			
		}
		
		public static function fail(message:String):void {
				Alert.show("Assert failed!\n" + message + "\n" + GetStackTrace());
		}
		
		public static function assertTrue(check:Boolean, message:String):void {
			if (!check) {
				Alert.show("Assert failed!\n" + message + "\n" + GetStackTrace());
			}
		}
		
		/**
		 * Returns the stack trace (filtered)
		 * @return stack trace
		 */
		public static function GetStackTrace() : String {
			if (Capabilities.isDebugger == true) {
				try { throw new Error(); }
				catch (e:Error) { return FilterStackTrace(e.getStackTrace()); }
				return "";
			}
			else
				return "Stack trace not available in non-debugger version.";
		}

		public static function FilterStackTrace(stack:String):String {
			var lines:Array = stack.split("\n");
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
		}
		
	}

}