package angel.game.script {
	import angel.common.Assert;
	import angel.common.ICleanup;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import angel.game.SimpleEntity;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EntityTriggers extends TriggerBase implements ICleanup {
		public var scriptFile:String; // cache so savegame can grab it
		
		public function EntityTriggers(me:SimpleEntity, filename:String) {
			super(me);
			scriptFile = filename;
			if (!Util.nullOrEmpty(filename)) {
				LoaderWithErrorCatching.LoadFile(filename, entityScriptXmlLoaded);
			}
		}
		
		private function entityScriptXmlLoaded(event:Event, param:Object, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml != null) {
				initFromXml(xml, filename);
			}
		}
			
		public function initFromXml(xml:XML, filename:String):void {
			var rootScriptForErrors:Script = new Script();
			rootScriptForErrors.initErrorList();
		
			if (xml.name() == "conversation") {
				// As a shorthand/convenience, if a script file has the enclosing topic "conversation" we turn its contents
				// into an onFrob trigger conversation action with the frobbed entity
				var newXml:XML = <script>
					<onFrob>
					</onFrob>
				</script>;
				xml.@id = ScriptContext.SpecialId(Script.SELF);
				newXml.onFrob.appendChild(xml);
				xml = newXml;
			}
			
			me.hasFrobScript = (xml.onFrob.length() > 0);
			
			createTriggeredScripts(me, xml, TriggerMaster.ON_DEATH, false, rootScriptForErrors, true);
			createTriggeredScripts(me, xml, TriggerMaster.ON_FROB, true, rootScriptForErrors, true);
			createTriggeredScripts(me, xml, TriggerMaster.ON_MOVE, true, rootScriptForErrors, true);
			createTriggeredScripts(me, xml, TriggerMaster.ON_REVIVE_FROB, true, rootScriptForErrors, false);
		
			rootScriptForErrors.displayAndClearParseErrors("Script errors in file " + filename);
		}
		
		private function createTriggeredScripts(me:Object, scriptXML:XML, triggerName:String,
								canFilterOnSpot:Boolean, rootScript:Script, supportsAny:Boolean):void {
			var scriptsForThisTrigger:XMLList = scriptXML.children().(name() == triggerName);
			if (scriptsForThisTrigger.length() > 0) {
				addTriggeredScriptsFromXmlList(me, me, scriptsForThisTrigger, triggerName, triggerName,
					false, canFilterOnSpot, rootScript);
			}
			
			if (supportsAny) {
				scriptsForThisTrigger = scriptXML.children().(name() == triggerName+"Any");
				if (scriptsForThisTrigger.length() > 0) {
					addTriggeredScriptsFromXmlList(me, me.room, scriptsForThisTrigger, triggerName, triggerName+"Any",
						true, canFilterOnSpot, rootScript);
				}
			}
		}
		
	}

}