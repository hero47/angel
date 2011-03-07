package angel.game {
	import angel.common.Assert

	// The room the player currently occupies is divided into Cells.  Each cell represents the contents of one
	// square on the map, including any terrain properties.
	public class Cell {
		
		public var contents:Vector.<Entity>;
		
		public function Cell() {
			
		}
		
		public function addEntity(entity:Entity):void {
			if (contents == null) {
				contents = new Vector.<Entity>();
			}
			contents.push(entity);
		}
		
		public function removeEntity(entity:Entity):void {
			Assert.assertTrue(contents != null && contents.indexOf(entity) >= 0, "Removing entity that's not there");
			if (contents != null) {
				var i:int = contents.indexOf(entity);
				if (i >= 0) {
					contents.splice(i, 1);
				}
			}
		}
		
		public function occupied():Boolean {
			return (contents != null && contents.length > 0);
		}
		
		public function solid():Boolean {
			if (contents != null) {
				for (var i:int = 0; i < contents.length; i++) {
					if (contents[i].solid) {
						return true;
					}
				}
			}
			return false;
		}
		
	}

}