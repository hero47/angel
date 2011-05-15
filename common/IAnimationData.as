package angel.common {
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAnimationData {
		
		function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void;
		function dataFinishedLoading(bitmapData:BitmapData):void;
		function standardImage():BitmapData;
		
	}
	
}