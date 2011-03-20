package angel.game {
	import angel.common.Assert
	import angel.common.Prop;

	// The room the player currently occupies is divided into Cells.  Each cell represents the contents of one
	// square on the map, including any terrain properties.
	public class Cell {
		
		public var contents:Vector.<Entity>;
		
		public function Cell() {
			
		}
		
		public function add(entity:Entity):void {
			if (contents == null) {
				contents = new Vector.<Entity>();
			}
			contents.push(entity);
		}
		
		public function remove(entity:Entity):void {
			Assert.assertTrue(contents != null && contents.indexOf(entity) >= 0, "Removing entity that's not there");
			if (contents != null) {
				var i:int = contents.indexOf(entity);
				if (i >= 0) {
					contents.splice(i, 1);
				}
			}
		}
		
		public function firstOccupant():Entity {
			if (!occupied()) {
				return null;
			}
			return contents[0];
		}
		
		public function occupied():Boolean {
			return (contents != null && contents.length > 0);
		}
		
		public function solid():uint {
			if (contents != null) {
				var solid:uint = 0;
				for (var i:int = 0; i < contents.length; i++) {
					solid |= contents[i].solid;
					return solid;
				}
			}
			return Prop.GHOST;
		}
		
	}

}