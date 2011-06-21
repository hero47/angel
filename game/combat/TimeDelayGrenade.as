package angel.game.combat {
	import angel.common.CharacterStats;
	import angel.common.CharResource;
	import angel.common.Prop;
	import angel.common.SingleImageAnimationData;
	import angel.common.Tileset;
	import angel.common.WeaponResource;
	import angel.game.brain.CombatBrainBomb;
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import angel.game.script.EntityTriggers;
	import angel.game.Settings;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class TimeDelayGrenade extends ThrownWeapon {
		
		public static const COUNTDOWN_COLOR:uint = 0xaa0000;
		
		private static const scriptXml:XML = <script>
			<onDeath>
				<detonate />
			</onDeath>
		</script>;
		
		private var delay:int;
		
		public function TimeDelayGrenade(resource:WeaponResource, id:String) {
			super(resource, id);
			delay = resource.delay;
		}
		
		override protected function deliverPayloadAt(room:Room, location:Point, baseDamage:int):void {
			var charResource:CharResource = Settings.catalog.retrieveCharacterResource("__grenade");
			charResource.unusedPixelsAtTopOfCell = Prop.HEIGHT - Tileset.TILE_HEIGHT;
			var entity:ComplexEntity = new ComplexEntity(charResource, "__grenade");
			entity.solidness = 0x0;
			entity.faction = ComplexEntity.FACTION_NONE;
			entity.combatBrainClass = CombatBrainBomb;
			entity.combatBrainParam = String(baseDamage) + ":" + String(delay);
			room.addEntity(entity, location);
			var combat:RoomCombat = RoomCombat(room.mode);
			combat.changeEntityTurnToJustBeforeCurrent(entity);
			
			entity.controllingOwnText = true;
			entity.setTextOverHead(String(delay), COUNTDOWN_COLOR);
			
			scriptXml.onDeath.detonate.@damage = baseDamage;
			entity.triggers = new EntityTriggers(entity, null);
			entity.triggers.initFromXml(scriptXml, null);
		}
		
	}

}