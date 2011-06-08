package angel.common {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class LoaderWithErrorCatching extends FileIOBase {

		private static const LOAD_FILE:int = 1;
		private static const LOAD_BYTES:int = 2;
		private static const LOAD_BYTES_FROM_FILE:int = 3;
		
		private var loader:Loader = null;
		private var urlLoader:URLLoader = null;
		private var dispatcher:EventDispatcher = null;
		
		private var completeParam:Object;
		
		// Don't use this constructor -- use static method LoadFile, LoadBytes, or LoadBytesFromFile
		// Callback takes parameters (event, completeParam, filenameForErrors)
		// callbackFail takes no parameter
		public function LoaderWithErrorCatching(type:int, filename:String, bytes:ByteArray,
				callbackWhenComplete:Function, completeParam:Object, callbackForFailure:Function) {		
			if (((type == LOAD_FILE) || (type == LOAD_BYTES_FROM_FILE)) && ((filename == null) || (filename == ""))) {
				Alert.show("Error! Missing filename.");
				if (callbackForFailure != null) {
					callbackForFailure();
				}
				return;
			}
			callback = callbackWhenComplete;
			callbackFail = callbackForFailure;
			this.completeParam = completeParam;
			filenameForErrorMessage = filename;
			if (type == LOAD_FILE) {
				urlLoader = new URLLoader();
				dispatcher = urlLoader;
			} else {
				loader = new Loader();
				dispatcher = loader.contentLoaderInfo;
			}
			//dispatcher.addEventListener(ProgressEvent.PROGRESS, progressListener);
			dispatcher.addEventListener(Event.COMPLETE, completeListener);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
			switch (type) {
				case LOAD_FILE:
					urlLoader.load(new URLRequest(filename));
				break;
				case LOAD_BYTES:
					loader.loadBytes(bytes);
				break;
				case LOAD_BYTES_FROM_FILE:
					loader.load(new URLRequest(filename));
				break;
			}	
		}
		
		public static function LoadBytesFromFile(filename:String, callbackWhenComplete:Function, callbackParam:Object = null, callbackForFailure:Function = null, loadIntoByteArray:Boolean = false):void {
			new LoaderWithErrorCatching(LOAD_BYTES_FROM_FILE, filename, null, callbackWhenComplete, callbackParam, callbackForFailure);
		}

		public static function LoadBytes(bytes:ByteArray, callbackWhenComplete:Function, callbackParam:Object = null, callbackForFailure:Function = null, loadIntoByteArray:Boolean = false):void {
			new LoaderWithErrorCatching(LOAD_BYTES, null, bytes, callbackWhenComplete, callbackParam, callbackForFailure);
		}

		public static function LoadFile(filename:String, callbackWhenComplete:Function, callbackParam:Object = null, callbackForFailure:Function = null, loadIntoByteArray:Boolean = false):void {
			new LoaderWithErrorCatching(LOAD_FILE, filename, null, callbackWhenComplete, callbackParam, callbackForFailure);
		}

		private function completeListener(event:Event):void {
			cleanup();
			callback(event, completeParam, filenameForErrorMessage);
		}
		
		override protected function cleanup():void {
			dispatcher.removeEventListener(Event.COMPLETE, completeListener);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorListener);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
			dispatcher = null;
			loader = null;
			urlLoader = null;
		}
		

	} // end class LoaderWithErrorCatching

}