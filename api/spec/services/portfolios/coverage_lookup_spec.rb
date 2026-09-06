# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/services/portfolios/coverage_lookup'

RSpec.describe Portfolios::CoverageLookup do
  # Duck-typed on purpose — the real CoverageMap rows are not needed to test the rule.
  FakeCoverage = Struct.new(:skill_id, :skill_label, :state)

  let(:maps) do
    [
      FakeCoverage.new('sk-eng-001', 'React / Frontend Development', 'covered'),
      FakeCoverage.new('sk-eng-002', 'System Design', 'not_yet'),
      FakeCoverage.new('sk-eng-003', 'Testing Discipline', 'partial'),
      FakeCoverage.new(nil, 'Micro-frontend Architecture', 'initiated')
    ]
  end

  subject(:lookup) { described_class.new(maps) }

  it 'treats a covered skill as discussed' do
    expect(lookup.discussed?(skill_id: 'sk-eng-001', skill_label: 'React / Frontend Development')).to be(true)
  end

  it 'treats partial and initiated as discussed — there is real evidence behind them' do
    expect(lookup.discussed?(skill_id: 'sk-eng-003', skill_label: 'Testing Discipline')).to be(true)
    expect(lookup.discussed?(skill_label: 'Micro-frontend Architecture')).to be(true)
  end

  it 'treats not_yet as never discussed' do
    expect(lookup.discussed?(skill_id: 'sk-eng-002', skill_label: 'System Design')).to be(false)
  end

  it 'falls back to the label when the model omitted the skill_id' do
    expect(lookup.discussed?(skill_label: 'react / frontend development')).to be(true)
  end

  it 'is conservative when there is no coverage row at all' do
    expect(lookup.discussed?(skill_id: 'sk-eng-999', skill_label: 'Kubernetes')).to be(false)
  end
end
