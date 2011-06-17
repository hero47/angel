package angel.common {
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAnimationData {
		
		function get animationClass():Class;
		function dataFinishedLoading(bitmapData:BitmapData, entry:CatalogEntry):void;
		function standardImage(down:Boolean = false):BitmapData;
		
		// for use in editor only; this (plus code in editor) is rather awkward.
		function increaseTop(additionalTop:int):int;
		
	}
	
}