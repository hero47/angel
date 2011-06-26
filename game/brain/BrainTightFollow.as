package angel.game.brain {
	import angel.game.ComplexEntity;
	import angel.game.RoomExplore;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class BrainTightFollow extends BrainFollow {
		
		public function BrainTightFollow(entity:ComplexEntity, roomExplore:RoomExplore, param:String) {
			super(entity, roomExplore, param);
			interval = 0; // check every frame. Set this after super() or initialization overwrites it!
		}
		
	}

}