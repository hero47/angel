package angel.common {
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Cleanup removes all listeners and references, and removes self from parent if it's a display object
	public interface ICleanup {
		function cleanup():void;
	}
	
}