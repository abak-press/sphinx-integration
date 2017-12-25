require 'spec_helper'

RSpec.describe ThinkingSphinx::Search do
  describe 'query with composite index' do
    context 'should ovverride conditions to query composite indexes' do
      let(:index) do
        ThinkingSphinx::Index::Builder.generate(ModelWithDisk, 'composite') do
          indexes '1', as: :one_idx
          composite_index :composite_idx, a_idx: "'a'", b_idx: "'b'"
        end
      end

      let(:riddle_client) { double('riddle client').as_null_object }

      before do
        allow(Riddle::Client).to receive(:new).and_return(riddle_client)
        allow(riddle_client).to receive(:query).with(any_args).and_return(matches: [])

        allow(ModelWithDisk).to receive(:sphinx_indexes).and_return([index])
        ThinkingSphinx.context.define_indexes
      end

      it do
        ModelWithDisk.search(conditions: {one_idx: 'one', b_idx: "b_1 | b_2", a_idx: "(a_2 | a_1)"}).to_a

        # документируем поведение с оператором '|' - части композитного индекса необходимо оборачивать в скобки
        expect(riddle_client).to have_received(:query)
          .with("@one_idx one @composite_idx (a_2 | a_1) b_1 | b_2", 'composite', any_args)
      end

      context 'when condition are simple' do
        it 'do not wrap condition in parentheses' do
          ModelWithDisk.search(conditions: {one_idx: 'one', b_idx: "b_1", a_idx: "(a_2 | a_1)"}).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1) b_1", 'composite', any_args)
        end
      end

      context 'when condition are AND' do
        it 'do not wrap condition in parentheses' do
          ModelWithDisk.search(conditions: {one_idx: 'one', b_idx: "b_1 b_2", a_idx: "(a_2 | a_1)"}).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1) b_1 b_2", 'composite', any_args)
        end
      end

      context 'when condition contains empty string' do
        it do
          ModelWithDisk.search(conditions: {one_idx: 'one', b_idx: ' ', a_idx: "(a_2 | a_1)"}).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1)", 'composite', any_args)
        end
      end

      context 'when condition contains nil' do
        it do
          ModelWithDisk.search(conditions: {one_idx: 'one', b_idx: nil, a_idx: "(a_2 | a_1)"}).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1)", 'composite', any_args)
        end
      end

      context 'when old composite condition' do
        it do
          ModelWithDisk.search(conditions: {
            one_idx: 'one',
            composite_idx: '(z_1 | z_2)', b_idx: '(b_1 | b_2)', a_idx: '(a_2 | a_1)'
          }).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (z_1 | z_2) (a_2 | a_1) (b_1 | b_2)", 'composite', any_args)
        end
      end

      context 'when old composite condition are simple' do
        it do
          ModelWithDisk.search(conditions: {
            one_idx: 'one',
            composite_idx: 'z_1', b_idx: '(b_1 | b_2)', a_idx: '(a_2 | a_1)'
          }).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx z_1 (a_2 | a_1) (b_1 | b_2)", 'composite', any_args)
        end
      end

      context 'when old composite condition are AND' do
        it do
          ModelWithDisk.search(conditions: {
            one_idx: 'one',
            composite_idx: 'z_1 z_2', b_idx: '(b_1 | b_2)', a_idx: '(a_2 | a_1)'
          }).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx z_1 z_2 (a_2 | a_1) (b_1 | b_2)", 'composite', any_args)
        end
      end

      context 'when old composite condition is a empty string' do
        it do
          ModelWithDisk.search(conditions: {
            one_idx: 'one',
            composite_idx: ' ', b_idx: '(b_1 | b_2)', a_idx: '(a_2 | a_1)'
          }).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1) (b_1 | b_2)", 'composite', any_args)
        end
      end

      context 'when old composite condition is a nil' do
        it do
          ModelWithDisk.search(conditions: {
            one_idx: 'one',
            composite_idx: nil, b_idx: '(b_1 | b_2)', a_idx: '(a_2 | a_1)'
          }).to_a

          expect(riddle_client).to have_received(:query)
            .with("@one_idx one @composite_idx (a_2 | a_1) (b_1 | b_2)", 'composite', any_args)
        end
      end
    end
  end
end
