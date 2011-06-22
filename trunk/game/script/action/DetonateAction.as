package angel.game.script.action {
	import angel.game.combat.ThrownWeapon;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.SimpleEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class DetonateAction implements IAction {
		private var id:String;
		private var damage:int;
		
		public static const TAG:String = "detonate";
		
		public function DetonateAction(id:String, damage:int) {
			this.id = id;
			this.damage = damage;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			var id:String = actionXml.@id;
			return new DetonateAction((id == "" ? ScriptContext.SpecialId(Script.SELF) : id), actionXml.@damage);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:SimpleEntity = context.entityWithScriptId(id, TAG);
			if (entity == null) {
				return null;
			} else if (entity == context.room.mainPlayerCharacter) {
				context.scriptError("Cannot detonate main player character.", TAG);
				return null;
			}
			var location:Point = entity.location;
			context.room.removeEntity(entity);
			ThrownWeapon.explodeAt(context.room, location, damage);
			return null;
		}
		
	}

}