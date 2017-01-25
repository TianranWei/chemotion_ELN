module Reporter
  module Docx
    class DetailReaction < Detail
      def initialize(args)
        super
        @obj = args[:reaction]
      end

      def content
        {
          title: title,
          collections: collection_label,
          equation_reaction: equation_reaction,
          equation_products: equation_products,
          status: status,
          starting_materials: starting_materials,
          reactants: reactants,
          products: products,
          solvents: displayed_solvents,
          description: description,
          purification: purification,
          tlc_rf: rf_value,
          tlc_solvent: tlc_solvents,
          tlc_description: tlc_description,
          observation: observation,
          analyses: analyses,
          literatures: literatures,
          not_last: id != last_id,
          show_tlc_rf: rf_value.to_f != 0,
          show_tlc_solvent: tlc_solvents.present?,
          is_reaction: true,
        }
      end

      private

      def title
        obj.name.present? ? obj.name : obj.short_label
      end

      def whole_equation
        @configs[:whole_diagram]
      end

      def equation_reaction
        DiagramReaction.new(obj: obj, format: @img_format).generate if whole_equation
      end

      def equation_products
        products_only = true
        DiagramReaction.new(obj: obj, format: @img_format).generate(products_only) if !whole_equation
      end

      def status
        path = case obj.status
          when "Successful" then
            Rails.root.join("lib", "template", "status", "successful.png")
          when "Planned" then
            Rails.root.join("lib", "template", "status", "planned.png")
          when "Not Successful" then
            Rails.root.join("lib", "template", "status", "not_successful.png")
          else
            Rails.root.join("lib", "template", "status", "blank.png")
        end
        Sablon::Image.create_by_path(path)
      end

      def literatures
        output = Array.new
        obj.literatures.each do |l|
          output.push({ title: l.title,
                        url: l.url
          })
        end
        return output
      end

      def analyses
        output = Array.new
        obj.products.each do |product|
          product.analyses.each do |analysis|
            metadata = analysis["extended_metadata"]
            content = JSON.parse(metadata["content"])

            output.push({
              sample: product.molecule.sum_formular,
              name: analysis.name,
              kind: metadata["kind"],
              status: metadata["status"],
              content: Sablon.content(:html, Delta.new(content).getHTML()),
              description: analysis.description
            })
          end
        end
        return output
      end

      def starting_materials
        output = Array.new
        obj.reactions_starting_material_samples.each do |s|
          sample = s.sample
          output.push({ name: sample.name,
                        iupac_name: sample.molecule.iupac_name,
                        short_label: sample.short_label,
                        formular: sample.molecule.sum_formular,
                        mol_w: sample.molecule.molecular_weight.try(:round, digit),
                        mass: sample.amount_g.try(:round, digit),
                        vol: sample.amount_ml.try(:round, digit),
                        density: sample.density.try(:round, digit),
                        mol: sample.amount_mmol.try(:round, digit),
                        equiv: s.equivalent.try(:round, digit)
          })
        end
        return output
      end

      def reactants
        output = Array.new
        obj.reactions_reactant_samples.each do |r|
          sample = r.sample
          output.push({ name: sample.name,
                        iupac_name: sample.molecule.iupac_name,
                        short_label: sample.short_label,
                        formular: sample.molecule.sum_formular,
                        mol_w: sample.molecule.molecular_weight.try(:round, digit),
                        mass: sample.amount_g.try(:round, digit),
                        vol: sample.amount_ml.try(:round, digit),
                        density: sample.density.try(:round, digit),
                        mol: sample.amount_mmol.try(:round, digit),
                        equiv: r.equivalent.try(:round, digit)
          })
        end
        return output
      end

      def products
        output = Array.new
        obj.reactions_product_samples.each do |p|
          sample = p.sample
          sample.real_amount_value ||= 0
          output.push({ name: sample.name,
                        iupac_name: sample.molecule.iupac_name,
                        short_label: sample.short_label,
                        formular: sample.molecule.sum_formular,
                        mol_w: sample.molecule.molecular_weight.try(:round, digit),
                        mass: sample.amount_g(:real).try(:round, digit),
                        vol: sample.amount_ml(:real).try(:round, digit),
                        density: sample.density.try(:round, digit),
                        mol: sample.amount_mmol(:real).try(:round, digit),
                        equiv: p.equivalent.nil? || (p.equivalent*100).nan? ? "0%" : "#{(p.equivalent*100).try(:round, 0)}%"
          })
        end
        return output
      end

      def purification
        obj.purification.compact.join(", ")
      end

      def description
        Sablon.content(:html, Delta.new(obj.description).getHTML())
      end

      def solvents
        obj.solvents
      end

      def solvent
        obj.solvent
      end

      def displayed_solvents
        if solvents.present?
          solvents.map do |s|
            volume = " (#{s.amount_ml.try(:round, digit)}ml)" if s.target_amount_value
            volume = " (#{s.amount_ml.try(:round, digit)}ml)" if s.real_amount_value
            s.preferred_label  + volume
          end.join(", ")
        else
          solvent
        end
      end

      def rf_value
        obj.rf_value
      end

      def tlc_solvents
        obj.tlc_solvents
      end

      def tlc_description
        obj.tlc_description
      end

      def observation
        obj.observation
      end
    end
  end
end
