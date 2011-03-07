package angel.roomedit {
	import angel.common.FileIOBase;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	public class FileChooser extends FileIOBase {
		private var fileReference:FileReference = null;
		private var loadIntoByteArray:Boolean;
		
		// if loadIntoByteArray is true: callback(filename, byteArray)
		// if false: callback(filename)
		// callbackForFailure takes no parameter
		public function FileChooser(callbackWhenComplete:Function, callbackForFailure:Function = null, loadIntoByteArray:Boolean = false) {
			callback = callbackWhenComplete;
			callbackFail = callbackForFailure;
			this.loadIntoByteArray = loadIntoByteArray;
			fileReference = new FileReference( );
			fileReference.addEventListener(Event.SELECT, selectListener);
			fileReference.addEventListener(Event.CANCEL, cancelListener);
			fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
			fileReference.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
			
			fileReference.browse();
		}

		protected function selectListener(event:Event):void {
			var filename:String = fileReference.name;
			if (loadIntoByteArray) {
				fileReference.addEventListener(Event.COMPLETE, completeListener);
				fileReference.load();
			} else {
				cleanup();
				callback(filename);
			}
		}
		
		private function completeListener(event:Event):void {
			var filename:String = fileReference.name;
			cleanup();
			var bytes:ByteArray = event.target.data;
			callback(filename, bytes);
		}
		
		override protected function cleanup():void {
			fileReference.removeEventListener(Event.COMPLETE, completeListener);
			fileReference.removeEventListener(Event.SELECT, selectListener);
			fileReference.removeEventListener(Event.CANCEL, cancelListener);
			fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
			fileReference.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
			fileReference = null;
		}

		private function cancelListener(event:Event):void {
			cleanup();
			if (callbackFail != null) {
				callbackFail();
			}
		}
		
	} // end class FileChooser
	
}