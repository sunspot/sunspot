require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Setup do
  context '#id_prefix_for_class' do
    subject { Sunspot::Setup.for(clazz).id_prefix_for_class }

    context 'when `id_prefix` is defined on model' do
      context 'as Proc' do
        let(:clazz) { PostWithProcPrefixId }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'as Symbol' do
        let(:clazz) { PostWithSymbolPrefixId }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'as String' do
        let(:clazz) { PostWithStringPrefixId }

        it 'returns `id_prefix` value' do
          is_expected.to eq('USERDATA!')
        end
      end
    end

    context 'when `id_prefix` is not defined on model' do
      let(:clazz) { PostWithoutPrefixId }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  context '#id_prefix_defined?' do
    subject { Sunspot::Setup.for(clazz).id_prefix_defined? }

    context 'when `id_prefix` is defined on model' do
      let(:clazz) { PostWithProcPrefixId }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when `id_prefix` is not defined on model' do
      let(:clazz) { PostWithoutPrefixId }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  context '#id_prefix_requires_instance?' do
    subject { Sunspot::Setup.for(clazz).id_prefix_requires_instance? }

    context 'when `id_prefix` is defined on model' do
      context 'as Proc' do
        let(:clazz) { PostWithProcPrefixId }

        it 'returns true' do
          is_expected.to be_truthy
        end
      end

      context 'as Symbol' do
        let(:clazz) { PostWithSymbolPrefixId }

        it 'returns true' do
          is_expected.to be_truthy
        end
      end

      context 'as String' do
        let(:clazz) { PostWithStringPrefixId }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when `id_prefix` is not defined on model' do
      let(:clazz) { PostWithoutPrefixId }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end
end
