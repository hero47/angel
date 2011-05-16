package angel.common {
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAnimationData {
		
		function get animationClass():Class;
		function prepareTemporaryVersionForUse(labelForTemporaryVersion:String):void;
		function dataFinishedLoading(bitmapData:BitmapData):void;
		function standardImage():BitmapData;
		
	}
	
}