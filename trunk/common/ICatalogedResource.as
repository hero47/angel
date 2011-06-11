package angel.common {
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface ICatalogedResource {
		
		function get catalogEntry():CatalogEntry;
		
		// Catalog calls this the first time an entry is requested.  Resource should do anything needed so that
		// it can be used, including creating its own BitmapData and filling it with temporary images.  These
		// may be displayed.  Later, when the real data finishes loading, it can be drawn over the temporary
		// images and then disposed.
		// CONSIDER: can we get rid of the places that call constructor directly and merge this into constructor?
		function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void;
		
		// Catalog calls this to draw over the temporary version with real data.
		// Some catalog types have more than one piece of data; the pass-along param allows identifying what is loaded.
		function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void;
		
	}
	
}