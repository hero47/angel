package angel.common {
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;

	
	public class FileIOBase {
			
		protected var callback:Function;
		protected var callbackFail:Function;
		
		public function FileIOBase() {
			
		}
		
		
		protected function cleanup():void {
			
		}
		

		protected function ioErrorListener(event:IOErrorEvent):void {
			cleanup();
			Alert.show("IO error: " + event.text);
			if (callbackFail != null) {
				callbackFail();
			}
		}

		protected function securityErrorListener(event:SecurityErrorEvent):void {
			cleanup();
			Alert.show("Security error: " + event.text);
			if (callbackFail != null) {
				callbackFail();
			}
		}


		
	} // end class FileIOBase

}