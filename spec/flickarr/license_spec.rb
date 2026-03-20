RSpec.describe Flickarr::License do
  describe '#initialize' do
    it 'looks up license by string id' do
      license = described_class.new('4')

      expect(license.id).to eq('4')
      expect(license.name).to eq('CC BY 2.0')
      expect(license.url).to eq('https://creativecommons.org/licenses/by/2.0/')
    end

    it 'looks up license by integer id' do
      license = described_class.new(9)

      expect(license.id).to eq('9')
      expect(license.name).to eq('CC0 1.0 Universal')
    end

    it 'handles All Rights Reserved' do
      license = described_class.new('0')

      expect(license.name).to eq('All Rights Reserved')
      expect(license.url).to be_nil
    end

    it 'handles unknown license ids' do
      license = described_class.new('99')

      expect(license.name).to eq('Unknown')
      expect(license.url).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash with id, name, and url' do
      license = described_class.new('5')

      expect(license.to_h).to eq(
        id:   '5',
        name: 'CC BY-SA 2.0',
        url:  'https://creativecommons.org/licenses/by-sa/2.0/'
      )
    end
  end
end
