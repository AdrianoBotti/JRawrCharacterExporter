package rawr.addoncompat;

import org.junit.jupiter.api.Test;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import rawr.base.character.Character;
import rawr.base.character.CharacterSlot;
import rawr.base.talents.TalentsBase;
import rawr.data.CharacterFixtureLoader;
import rawr.data.XmlLoader;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Imports the Lua test harness's committed character XML samples through JRawr's real importer.
 *
 * <p>This is intentionally a cross-repository contract test. It lives in the addon repository but
 * is copied into JRawr's rawr-data test source tree by tools/check-jrawr-import.sh, so it runs
 * with JRawr's dependencies and the same CharacterFixtureLoader used by the application import.
 */
class JRawrCharacterExporterImportTest {
    private static final Set<String> JRAWR_MODELS = Set.of(
        "Mage", "RestoSham", "Cat", "Bear", "Moonkin", "Elemental", "Enhance",
        "Healadin", "HealPriest", "ShadowPriest", "ProtWarr", "Retribution",
        "ProtPaladin", "Hunter", "Rogue", "Tree", "TankDK", "Warlock",
        "DPSDK", "DPSWarr");

    private static final Set<String> NON_SLOT_ELEMENTS = Set.of(
        "Name", "Realm", "Region", "Race", "Class", "CurrentModel",
        "EnforceMetagemRequirements", "PrimaryProfession", "SecondaryProfession",
        "AvailableItems", "ActiveBuffs", "CalculationToOptimize",
        "CalculationOptions", "CustomGemmingTemplates",
        "GemmingTemplateOverrides", "CustomItemInstances",
        "ItemFilterEnabledOverride", "OptimizationRequirements", "Boss",
        "MageTalents", "WarriorTalents", "ShamanTalents", "DruidTalents",
        "PaladinTalents", "PriestTalents", "HunterTalents", "RogueTalents",
        "DeathKnightTalents", "WarlockTalents");

    @Test
    void everyAddonSampleImportsAndRoundTripsTalents() throws Exception {
        String samplesPath = System.getenv("JRAWR_ADDON_SAMPLES");
        assertThat(samplesPath).as("JRAWR_ADDON_SAMPLES").isNotNull();
        Path samples = Path.of(samplesPath);
        assertThat(Files.isDirectory(samples)).as("JRAWR_ADDON_SAMPLES").isTrue();

        List<Path> files;
        try (Stream<Path> stream = Files.list(samples)) {
            files = stream
                .filter(path -> path.toString().endsWith(".xml"))
                .sorted()
                .toList();
        }
        assertThat(files).as("sample XML files").isNotEmpty();

        for (Path file : files) {
            assertSample(file);
        }
    }

    private static void assertSample(Path file) throws Exception {
        Element root = XmlLoader.parse(file).getDocumentElement();
        Character character = CharacterFixtureLoader.load(file);
        String name = file.getFileName().toString();

        assertThat(character.getName()).as("%s Name", name).isNotBlank();
        assertThat(character.getRealm()).as("%s Realm", name).isNotNull();
        assertThat(character.getCurrentModel())
            .as("%s CurrentModel", name)
            .isIn(JRAWR_MODELS);
        assertThat(character.getRace()).as("%s Race", name).isNotNull();
        assertThat(character.getCharacterClass()).as("%s Class", name).isNotNull();
        assertThat(character.getRegion()).as("%s Region", name).isNotNull();
        assertThat(character.getPrimaryProfession()).as("%s PrimaryProfession", name).isNotNull();
        assertThat(character.getSecondaryProfession()).as("%s SecondaryProfession", name).isNotNull();

        String talentElement = character.getCharacterClass() + "Talents";
        String expectedTalents = XmlLoader.text(root, talentElement);
        TalentsBase talents = character.getCurrentTalents();
        assertThat(expectedTalents).as("%s %s element", name, talentElement).isNotNull();
        assertThat(talents).as("%s %s loaded", name, talentElement).isNotNull();
        assertThat(talents.toString())
            .as("%s %s round-trip", name, talentElement)
            .isEqualTo(expectedTalents);

        assertThat(character.getAvailableItems().size())
            .as("%s AvailableItems count", name)
            .isEqualTo(countChildren(root, "AvailableItems"));

        for (Node node = root.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node.getNodeType() != Node.ELEMENT_NODE) {
                continue;
            }

            String tag = ((Element) node).getTagName();
            if (NON_SLOT_ELEMENTS.contains(tag)) {
                continue;
            }

            CharacterSlot slot;
            try {
                slot = CharacterSlot.valueOf(tag);
            } catch (IllegalArgumentException ex) {
                throw new AssertionError(name + ": unknown top-level element <" + tag + ">", ex);
            }
            assertThat(character.get(slot))
                .as("%s slot %s loaded", name, tag)
                .isNotNull();
        }
    }

    private static int countChildren(Element root, String tag) {
        int count = 0;
        for (Node node = root.getFirstChild(); node != null; node = node.getNextSibling()) {
            if (node.getNodeType() == Node.ELEMENT_NODE
                    && ((Element) node).getTagName().equals(tag)) {
                count++;
            }
        }
        return count;
    }
}
