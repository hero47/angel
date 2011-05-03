package angel.common {
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;

	
	public class FileIOBase {
			
		protected var callback:Function;
		protected var callbackFail:Function;
		protected var filenameForErrorMessage:String;
		
		public function FileIOBase() {
			
		}
		
		
		protected function cleanup():void {
			
		}
		

		protected function ioErrorListener(event:IOErrorEvent):void {
			cleanup();
			var message:String = "IO error " + event.text;
			if (message.indexOf("2035") >= 0) {
				message = "Cannot open file " + filenameForErrorMessage;
			} else if (message.indexOf("2124") >= 0) {
				message = "Cannot load image from " + filenameForErrorMessage + "; unknown file type."
			}
			Alert.show(message);
			if (callbackFail != null) {
				callbackFail();
			}
		}

		protected function securityErrorListener(event:SecurityErrorEvent):void {
			cleanup();
			//var message:String = "Security error " + event.text;
			var message:String = "Security error on file " + filenameForErrorMessage;
			Alert.show(message);
			if (callbackFail != null) {
				callbackFail();
			}
		}


		
	} // end class FileIOBase

}